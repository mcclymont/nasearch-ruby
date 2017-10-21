class CreateFirstSchema < ActiveRecord::Migration[5.1]
  def change
    create_table :shows do |t|
      t.string :name, null: false
    end

    create_table :notes do |t|
      t.integer :show_id, null: false
      t.text :topic, null: false
      t.text :title, null: false
      t.text :text, null: false
    end

    create_table :sources, id: false do |t|
      t.integer :show_id, null: false
      t.string :file_type, null: false
      t.text :text, null: false
    end

    create_table :url_entries do |t|
      t.integer :note_id, null: false
      t.text :text, null: false
      t.text :url, null: false
    end
  end
end
