class Note < ApplicationRecord
  belongs_to :show
  has_many :url_entries, dependent: :delete_all
  before_save :truncate_text!

  def inspect
    "#<Note id: #{id}, show_id: #{show_id}, topic: #{topic.inspect}, title: #{title.inspect}?"
  end

  private

  def truncate_text!
    # Actual max size for making into tsvector: 1_048_575
    if text.length > 900.kilobytes
      self.text = text.first(900.kilobytes) + "\n-------TRUNCATED-------"
    end
  end
end
