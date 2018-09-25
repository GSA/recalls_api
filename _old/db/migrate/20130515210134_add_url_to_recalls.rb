class AddUrlToRecalls < ActiveRecord::Migration
  def change
    add_column :recalls, :url, :string, null: true
  end
end
