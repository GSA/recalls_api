class CreateRecalls < ActiveRecord::Migration
  def change
    create_table :recalls do |t|
      t.string :recall_number, limit: 10
      t.integer :y2k
      t.date :recalled_on
      t.string :organization, limit: 10

      t.timestamps
    end
    add_index :recalls, :recall_number
  end
end
