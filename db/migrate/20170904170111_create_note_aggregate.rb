class CreateNoteAggregate < ActiveRecord::Migration[5.1]
  def change
    create_table :note_aggregates do |t|
      t.integer :note_id, null: false
      t.string :topic
      t.string :title
      t.text :text
    end
  end
end
