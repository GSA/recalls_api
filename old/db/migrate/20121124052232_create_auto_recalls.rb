class CreateAutoRecalls < ActiveRecord::Migration
  def change
    create_table :auto_recalls do |t|
      t.references :recall
      t.string :make, limit: 25
      t.string :model
      t.integer :year
      t.string :manufacturer, limit: 40
      t.date :manufacturing_begin_date
      t.date :manufacturing_end_date
      t.string :recalled_component_id
      t.string :component_description

      t.timestamps
    end
    add_index :auto_recalls, [:recall_id, :recalled_component_id]
  end
end
