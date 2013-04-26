class UsersController < ApplicationController
	before_filter :signed_in_user, only: [:index, :edit, :update, :destroy, :following, :followers]
	before_filter :banned_action_for_signed_in_user, only: [:new, :create]
	before_filter :correct_user, only: [:edit, :update]
	before_filter :admin_user, only: :destroy
  
  def get_data_from_local_repository
    require 'ElectronicHealthRecord'
    
    ehr = EHR::ElectronicHealthRecord.new
    #ehr.load_file(@user.health_records.path)
    ehr.load_file(Rails.root.join('health_record_repo.yml'))
    
    return ehr.cholesterol_measurements
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
  
  def sync_from_healthvault
  
  end
  
  def generate_cholesterol_chart
    # Data Chart for cholesterol
    data_table = GoogleVisualr::DataTable.new
    
    # Add Column Headers
    data_table.new_column('string', 'Date' )
    data_table.new_column('number', 'HDL')
    data_table.new_column('number', 'LDL')
    data_table.new_column('number', 'Total Cholesterol')
    data_table.new_column('number', 'Triglyceride')

    # Add Rows and Values
    my_data = get_data_from_local_repository
    data_table.add_rows(my_data)

    option = { width: 500, height: 240, title: 'Cholesterol' }
    @chart = GoogleVisualr::Interactive::AreaChart.new(data_table, option)
  end
  
  def show
		@user = User.find(params[:id])
		@microposts = @user.microposts.paginate(page: params[:page])

    @chart = generate_cholesterol_chart
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
