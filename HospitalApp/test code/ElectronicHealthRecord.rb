require 'psych'

module EHR

  class Demographics
    attr_accessor :first_name, :middle_name, :last_name    
  end
  
  class Pharmacy
    attr_accessor :name, :address, :phone_number
  end
  
  class Medication
    attr_accessor :name, :distributing_pharmacy
  end
  
  class Allergy
    attr_accessor :name, :reaction
  end

  class ElectronicHealthRecord
    attr_accessor :hash, :demographics
    
    def load_file(file_name)
      # puts "reading file..."
      @hash = Psych.load_file(file_name)
      # puts "done"
    end
    
    def dump_file(file_name)
      file = File.open(file_name, "w")
      Psych.dump(@hash, file)
      file.close
    end
    
    def assign_attributes_based_on_hash(yaml_hash)
      ehr_version = yaml_hash["ehr_version"]
      case ehr_version
      when "1.0.0"
        
      else
        raise StandardError, "Invalid Electronic Health Record"
      end    
    end
    
  end
  
end

### Testing code
# ehr = EHR::ElectronicHealthRecord.new
# ehr.load_file("some.yml")
# puts ehr.hash

# ehr.dump_file("testfile3.yml")

#wait for use to type something
gets