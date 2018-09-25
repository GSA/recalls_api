class CreateFoodRecalls < ActiveRecord::Migration
  def change
    create_table :food_recalls do |t|
      t.references :recall
      t.string :summary, null: false
      t.text :description, null: false
      t.string :url, null: false
      t.string :food_type, limit: 10

      t.timestamps
    end
    add_index :food_recalls, :recall_id
  end
end
