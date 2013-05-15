# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130515210134) do

  create_table "auto_recalls", :force => true do |t|
    t.integer  "recall_id"
    t.string   "make",                     :limit => 25
    t.string   "model"
    t.integer  "year"
    t.string   "manufacturer",             :limit => 40
    t.date     "manufacturing_begin_date"
    t.date     "manufacturing_end_date"
    t.string   "recalled_component_id"
    t.string   "component_description"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
  end

  add_index "auto_recalls", ["recall_id", "recalled_component_id"], :name => "index_auto_recalls_on_recall_id_and_recalled_component_id"

  create_table "food_recalls", :force => true do |t|
    t.integer  "recall_id"
    t.string   "summary",                   :null => false
    t.text     "description",               :null => false
    t.string   "url",                       :null => false
    t.string   "food_type",   :limit => 10
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  add_index "food_recalls", ["recall_id"], :name => "index_food_recalls_on_recall_id"

  create_table "recall_details", :force => true do |t|
    t.integer  "recall_id"
    t.string   "detail_type"
    t.string   "detail_value"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "recall_details", ["recall_id"], :name => "index_recall_details_on_recall_id"

  create_table "recalls", :force => true do |t|
    t.string   "recall_number", :limit => 10
    t.integer  "y2k"
    t.date     "recalled_on"
    t.string   "organization",  :limit => 10
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.string   "url"
  end

  add_index "recalls", ["recall_number"], :name => "index_recalls_on_recall_number"

end
