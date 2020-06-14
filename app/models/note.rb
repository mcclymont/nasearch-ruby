class Note < ApplicationRecord
  belongs_to :show
  has_many :url_entries, dependent: :delete_all
  before_save -> { self.text = truncate_text(MAX_STORAGE_SIZE) }

  MAX_STORAGE_SIZE = 900.kilobytes
  MAX_AJAX_SIZE = 3.kilobytes

  def inspect
    "#<Note id: #{id}, show_id: #{show_id}, topic: #{topic.inspect}, title: #{title.inspect}?"
  end

  def truncate_text(size=MAX_AJAX_SIZE)
    if text.length > size
      text.first(size) + "\n-------TRUNCATED-------"
    else
      text
    end
  end

  def as_json(*_options)
    slice(:show_id, :title, :topic).merge(text: truncate_text)
  end

  def set_document(urls)
    split_filenames = []
    urls.each do |hash|
      filename = File.basename(hash[:url])
      split_filenames << filename.split(/[_\-.]/).join(" ")
    end

    self.document = ([title] + split_filenames + [text]).join(" \n")
  end
end
