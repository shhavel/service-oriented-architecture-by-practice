class AddIndexesToZipCodes < ActiveRecord::Migration
  def up
    add_index :zip_codes, :street_name
    add_index :zip_codes, :building_number
    add_index :zip_codes, :city
    add_index :zip_codes, :state
  end

  def down
    remove_index :zip_codes, :street_name
    remove_index :zip_codes, :building_number
    remove_index :zip_codes, :city
    remove_index :zip_codes, :state
  end
end
