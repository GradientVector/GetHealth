require 'SecureRandom'

class HealthRecord < ActiveRecord::Base

  belongs_to :user, dependent: :destroy

  after_initialize do
    if self.path.blank?
      # Get the health records directory
      health_records_dir = Rails.root.join('health_records')      
      # Generate a unique name for the new health record folder    
      folder_name = SecureRandom.uuid
      health_record_path = health_records_dir + folder_name
      # begin
        # folder_name = SecureRandom.uuid
        # health_record_path = health_records_dir + folder_name
        # folder_name_is_free = Dir.exist?(health_record_path)
      # end while not folder_name_is_free
      self.path = health_record_path
    end
  end
  
  validates :user_id, presence: true
  validates :path, presence: true, 
    uniqueness: { case_sensitive: false }
    
  after_validation do
    if self.path.nil? or !Dir.exist?(self.path)
      errors[:path] = "needs to point to a valid folder"
    end
  end
end