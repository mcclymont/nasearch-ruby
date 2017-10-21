class Note < ApplicationRecord
  belongs_to :show
  has_many :url_entries, dependent: :delete_all

  def inspect
    "#<Note id: #{id}, show_id: #{show_id}, topic: #{topic.inspect}, title: #{title.inspect}?"
  end
end
