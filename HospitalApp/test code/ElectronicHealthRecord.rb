require 'psych'

module EHR

  # EntryTypes = { 
    # demographics: { 
      # :one,
      # fields: {
        # :first_name,
        # :middle_name,
        # :last_name,
        # :date_of_birth 
      # }
    # },
    # cholesterol_measurement: {
      # :many,
      # fields: {
        # :date,
        # :hdl,
        # :ldl,
        # :total,
        # :triglyceride
      # }
    # }
  # }

  class Demographics
    attr_accessor :first_name, :middle_name, :last_name, :date_of_birth
  end
  
  # class Pharmacy
    # attr_accessor :name, :address, :phone_number
  # end
  
  # class Medication
    # attr_accessor :name, :distributing_pharmacy
  # end
  
  # class Allergy
    # attr_accessor :name, :reaction
  # end

  class CholesterolMeasurement
    attr_accessor :date, :hdl, :ldl, :total, :triglyceride
  end
  
  class ElectronicHealthRecord
    attr_accessor :hash, :demographics, :cholesterol_measurements
    
    def load_file(file_name)
      # puts "reading file..."
      @hash = Psych.load_file(file_name)
      
      # puts "done"
      #assign_attributes_based_on_hash(@hash)
    end
    
    def dump_file(file_name)
      file = File.open(file_name, "w")
      Psych.dump(@hash, file)
      file.close
    end

    def version
      @hash["ehr_version"]
    end
    
    def demographics
      @hash["demographics"]
    end
    
    def assign_attributes_based_on_hash(yaml_hash)
      yaml_hash.each do |record_type, record_value|
        case record_type
        when "demographics"
          @demographics = Demographics.new
          @demographics.first_name = record_value["first_name"]
          @demographics.middle_name = record_value["middle_name"]
          @demographics.last_name = record_value["last_name"]
          @demographics.date_of_birth = record_value["date_of_birth"]
        when "cholesterol_measurements"
          @cholesterol_measurements = []
          record_value.each do |field|
            cm = CholesterolMeasurement.new
            cm.date = field["date"]
            cm.hdl = field["hdl"]
            cm.ldl = field["ldl"]
            cm.total = field["total"]
            cm.triglyceride = field["triglyceride"]
            @cholesterol_measurements << cm
          end  
        end
      end  
    end
    
  end
  
end

# ### Testing code
# ehr = EHR::ElectronicHealthRecord.new
# ehr.load_file("some.yml")
# puts "---=== Hash ===---"
# puts ehr.hash
# puts "---=== Demographics ===---"
# d = ehr.demographics
# puts d.first_name
# puts d.middle_name
# puts d.last_name
# puts d.date_of_birth
# puts "---=== Cholesterol Measurements ===---"
# puts ehr.cholesterol_measurements.to_s

# ehr.dump_file("testfile3.yml")

#wait for use to type something
#gets