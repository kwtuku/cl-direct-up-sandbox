class AddPositionToImages < ActiveRecord::Migration[6.1]
  def change
    add_column :images, :position, :integer
  end
end
