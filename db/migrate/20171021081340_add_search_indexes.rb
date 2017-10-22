class AddSearchIndexes < ActiveRecord::Migration[5.1]
  def up
    execute <<-SQL
      CREATE EXTENSION IF NOT EXISTS pg_trgm;

      CREATE INDEX notes_text_gin  on notes using GIN(to_tsvector('english', text));
      CREATE INDEX notes_title_gin on notes using GIN(to_tsvector('english', title));

      CREATE INDEX url_entries_url on url_entries using GIN(lower(url) gin_trgm_ops);
    SQL
  end

  def down
    remove_index :notes, name: 'notes_text_gin'
    remove_index :notes, name: 'notes_title_gin'
    remove_index :url_entries, name: 'url_entries_url'
  end
end
