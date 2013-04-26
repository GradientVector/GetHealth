class CreateHealthRecords < ActiveRecord::Migration
  def change
    create_table :health_records do |t|
      t.integer :user_id
      t.string :path
      
      t.timestamps
    end
      
    add_index :health_records, :user_id
  end

end
