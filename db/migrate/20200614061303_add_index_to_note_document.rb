class AddIndexToNoteDocument < ActiveRecord::Migration[6.0]
  def up
    execute 'SET statement_timeout = 0;'
    execute <<-SQL
      CREATE INDEX notes_document_gin on notes using GIN(to_tsvector('english', document));
    SQL
  end

  def down
    remove_index :notes, name: :notes_document_gin
  end
end
