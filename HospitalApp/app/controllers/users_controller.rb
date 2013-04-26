class UsersController < ApplicationController
	before_filter :signed_in_user, only: [:index, :edit, :update, :destroy, :following, :followers, :sync, :add_cholesterol_measurement]
	before_filter :banned_action_for_signed_in_user, only: [:new, :create]
	before_filter :correct_user, only: [:edit, :update]
	before_filter :admin_user, only: [:destroy, :sync, :add_cholesterol_measurement]
  
  HEALTH_RECORD_DIR_PATH = Rails.root.join('health_records').join("1")
  HEALTH_RECORD_FILE_NAME = 'health_record.yml'
  HEALTH_RECORD_FILE_PATH = HEALTH_RECORD_DIR_PATH.join(HEALTH_RECORD_FILE_NAME)
  
  def get_data_from_local_repository
    require 'ElectronicHealthRecord'
    
    ehr = EHR::ElectronicHealthRecord.new
    #ehr.load_file(@user.health_records.path)
    ehr.load_file(HEALTH_RECORD_FILE_PATH)
    
    return ehr
  end
  
  def get_data_from_api
    require 'net/http'

    apiUri = URI('http://seattle.geo.netio.ca/varcharmax/api/cholesterol_individual')
    response = Net::HTTP.get(apiUri)

    require 'json'
    jsonResponse = JSON.load(response)

    myArray = []

    jsonResponse.each do |j|
      myDataRow = []
      myDataRow << j["Date"].to_s
      myDataRow << j["HDL"].to_i
      myDataRow << j["LDL"].to_i
      myDataRow << j["TotalCholesterol"].to_i
      myDataRow << j["Triglyceride"].to_i
      myArray << myDataRow
    end

    return myArray
  end
  
  def get_hdl(array_of_cholesterol_measurements)
    date_and_hdl = []
    array_of_cholesterol_measurements.each do |cm|
      date_and_hdl << [cm[0], cm[1]]
    end
    date_and_hdl
  end
  
  def get_ldl(array_of_cholesterol_measurements)
    date_and_ldl = []
    array_of_cholesterol_measurements.each do |cm|
      date_and_ldl << [cm[0], cm[2]]
    end
    date_and_ldl
  end
  
  def get_total(array_of_cholesterol_measurements)
    date_and_total = []
    array_of_cholesterol_measurements.each do |cm|
      date_and_total << [cm[0], cm[3]]
    end
    date_and_total
  end
  
  def get_triglyceride(array_of_cholesterol_measurements)
    date_and_triglyceride = []
    array_of_cholesterol_measurements.each do |cm|
      date_and_triglyceride << [cm[0], cm[4]]
    end
    date_and_triglyceride
  end
  
  def sync_from_healthvault
    get_data_from_api
  end
  
  def generate_cholesterol_charts
    # create data charts for cholesterol

    # Add Rows and Values
    cms = get_data_from_local_repository.cholesterol_measurements    

    # Add Column Headers
    hdl_table_data = GoogleVisualr::DataTable.new
    hdl_table_data.new_column('string', 'Date' )
    hdl_table_data.new_column('number', 'HDL')
    hdl_table_data.add_rows(get_hdl(cms))
    hdl_option = { width: 600, height: 240, title: 'HDL' }
    @hdl_chart = GoogleVisualr::Interactive::AreaChart.new(hdl_table_data, hdl_option)
    
    # Add Column Headers
    ldl_table_data = GoogleVisualr::DataTable.new
    ldl_table_data.new_column('string', 'Date' )
    ldl_table_data.new_column('number', 'LDL')
    ldl_table_data.add_rows(get_ldl(cms))
    ldl_option = { width: 600, height: 240, title: 'LDL' }
    @ldl_chart = GoogleVisualr::Interactive::AreaChart.new(ldl_table_data, ldl_option)
    
    # Add Column Headers
    total_table_data = GoogleVisualr::DataTable.new
    total_table_data.new_column('string', 'Date' )
    total_table_data.new_column('number', 'Total Cholesterol')
    total_table_data.add_rows(get_total(cms))
    total_option = { width: 600, height: 240, title: 'Total' }
    @total_chart = GoogleVisualr::Interactive::AreaChart.new(total_table_data, total_option)
    
    # Add Column Headers
    triglyceride_table_data = GoogleVisualr::DataTable.new
    triglyceride_table_data.new_column('string', 'Date' )
    triglyceride_table_data.new_column('number', 'Triglyceride')
    triglyceride_table_data.add_rows(get_triglyceride(cms))
    triglyceride_option = { width: 600, height: 240, title: 'Triglyceride' }
    @triglyceride_chart = GoogleVisualr::Interactive::AreaChart.new(triglyceride_table_data, triglyceride_option)
  end
  
  def sync
    @user = User.find(params[:id])
  
    require 'net/http'
    require 'uri'
    
    cm = get_data_from_local_repository.cholesterol_measurements.last
    
    date = cm[0]
    hdl = cm[1]
    ldl = cm[2]
    total = cm[3]
    triglyceride = cm[4]
    
    apiUri = URI('http://seattle.geo.netio.ca/varcharmax/api/cholesterol_individual')
    response = Net::HTTP::Post.new(apiUri.path)
          response.content_type = ' application/x-www-form-urlencoded'
          response.body = 
          "=<ArrayOfCholesterol xmlns:i='http://www.w3.org/2001/XMLSchema-instance' xmlns='http://schemas.datacontract.org/2004/07/MvcApplication1'>
            <Cholesterol>
              <Date>#{date}</Date>
              <HDL>#{hdl}</HDL>
              <LDL>#{ldl}</LDL>
              <TotalCholesterol>#{total}</TotalCholesterol>
              <Triglyceride>#{triglyceride}</Triglyceride>
            </Cholesterol>
          </ArrayOfCholesterol>"

    response = Net::HTTP.start(apiUri.host, apiUri.port) { |http| http.request(response) }
    
    flash[:success] = "Data synced"
    redirect_to (@user)
  end
  
  def add_cholesterol_measurement
  
		@user = User.find(params[:id])
  
		ehr = get_data_from_local_repository
    measurement = {"date" => Time.now.to_s,
    "hdl" => params[:hdl].to_i,
    "ldl" => params[:ldl].to_i,
    "total" => params[:total].to_i,
    "triglyceride" => params[:triglyceride].to_i}
    ehr.hash["cholesterol_measurements"] << measurement
        
		ehr.dump_file(HEALTH_RECORD_FILE_PATH)
		ehr.commit_changes(HEALTH_RECORD_DIR_PATH)
    
    flash[:success] = "Cholesterol measurement added to local repository"
		redirect_to (@user)
  end
  
  def show
		@user = User.find(params[:id])
		@microposts = @user.microposts.paginate(page: params[:page])

		generate_cholesterol_charts
		@cholesterol_measurement = EHR::CholesterolMeasurement.new
  end
  
  def new
		@user = User.new
  end
  
  def create
		@user = User.new(params[:user])
		if @user.save
			# Handle a successful save.
			sign_in @user
			flash[:success] = "Welcome to the Sample App!"
			redirect_to @user
		else
			render 'new'
		end
  end  
  
  def index
		@users = User.paginate(page: params[:page])
  end
  
  def edit
  end
  
  def update	
		if @user.update_attributes(params[:user])
			# Handle a successful update.
			sign_in @user
			flash[:success] = "Profile updated"
			redirect_to @user
		else
			render "edit"
		end
  end
  
  def destroy
		user = User.find(params[:id])
		unless current_user?(user)
			user.destroy
			flash[:success] = "User destroyed."
			redirect_to users_url
		else
			redirect_to root_path, notice: "Admin users are not allowed to destroy themselves."
		end
  end
	
	def following
		@title = "Following"
		@user = User.find(params[:id])
		@users = @user.followed_users.paginate(page: params[:page])
		render "show_follow"
	end
	
	def followers
		@title = "Followers"
		@user = User.find(params[:id])
		@users = @user.followers.paginate(page: params[:page])
		render "show_follow"
	end
  
  private		
		def banned_action_for_signed_in_user
			if signed_in?
				redirect_to root_path, notice: "Signed-in users are not allowed to create a new user account."
			end
		end
		
		def correct_user
			@user = User.find(params[:id])
			redirect_to(root_path) unless current_user?(@user)
		end
		
		def admin_user
			redirect_to(root_path) unless current_user.admin?
		end
end
