class CreateImages < ActiveRecord::Migration[6.1]
  def change
    create_table :images do |t|
      t.references :article, null: false, foreign_key: true
      t.string :cl_id

      t.timestamps
    end
  end
end
