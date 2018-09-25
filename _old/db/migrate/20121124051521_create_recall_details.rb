class CreateRecallDetails < ActiveRecord::Migration
  def change
    create_table :recall_details do |t|
      t.references :recall
      t.string :detail_type
      t.string :detail_value

      t.timestamps
    end
    add_index :recall_details, :recall_id
  end
end
