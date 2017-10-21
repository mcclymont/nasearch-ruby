require 'zlib'

class Note < ApplicationRecord
  belongs_to :show
  has_one :note_aggregate
  has_many :url_entries, dependent: :delete_all
  has_many :text_entries, dependent: :delete_all

  def entries
    text_entries + url_entries
  end

  def process_note_aggregate!
    result = StringIO.new
    entries.each do |e|
      next unless e.index?
      result << e.to_s
      result << ' '
    end

    return if result.length.zero?

    note_aggregate ||= NoteAggregate.new(note: self)
    note_aggregate.update!(
      title: title,
      topic: topic,
      text:  result.string
    )
  end
end
