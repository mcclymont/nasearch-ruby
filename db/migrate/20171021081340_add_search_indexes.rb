class AddSearchIndexes < ActiveRecord::Migration[5.1]
  def up
    execute <<-SQL
      CREATE EXTENSION pg_trgm;

      CREATE INDEX notes_text_gin  on notes using GIN(to_tsvector('english', text));
      CREATE INDEX notes_title_gin on notes using GIN(to_tsvector('english', title));

      CREATE INDEX url_entries_url on url_entries using GIN(url gin_trgm_ops);
    SQL
  end

  def down
    %w(notes_text_gin notes_title_gin url_entries_url).each do |index|
      remove_index index
    end
  end
end
