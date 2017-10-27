class Source < ApplicationRecord
  belongs_to :show
  before_validation :set_show!
  after_initialize :include_module

  NEW_HTML_FORMAT_START = 590

  def include_module
    return if respond_to? :process_text!

    if file_type == 'opml'
      extend ::Loaders::OPML
    elsif file_type == 'html'
      if show_id <= NEW_HTML_FORMAT_START
        extend ::Loaders::NewHTML
      else
        Rails.logger.warning "File type #{file_type} not implemented"
      end
    else
      Rails.logger.warning "File type #{file_type} not implemented"
    end
  end

  def file_type=(val)
    super(val).tap { include_module }
  end

  def inspect
    "#<Source show_id: #{show_id} file_type: #{file_type}>"
  end

  def set_show!
    self.show = Show.create!(id: show_id, name: extract_title) if
      show_id && !Show.exists?(show_id)
  end

  def delete_notes!
    note_ids = show.notes.pluck(:id)
    UrlEntry.where(note: note_ids).delete_all
    Note.where(show: show).delete_all
  end
end
