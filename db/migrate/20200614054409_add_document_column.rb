class AddDocumentColumn < ActiveRecord::Migration[6.0]
  def up
    add_column :notes, :document, :text
    # execute <<-SQL
    #   CREATE INDEX notes_document_gin on notes using GIN(to_tsvector('english', document));
    # SQL
  end

  def down
    # remove_index :notes, name: :notes_document_gin
    remove_column :notes, :document
  end
end
