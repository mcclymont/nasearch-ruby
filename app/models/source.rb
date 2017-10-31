class Source < ApplicationRecord
  belongs_to :show
  before_validation :set_show!
  after_initialize :include_module

  NEW_HTML_FORMAT_START = 590

  def include_module
    return if respond_to? :process_text! || show_id.nil? || file_type.nil?

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

  def show_id=(val)
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

  def self.process!(show_num, reprocess=false, redownload=false)
    require 'net/http'

    show = Show.find_by(id: show_num)
    return show if show && !reprocess

    if show.nil? || redownload
      domain = (show_num < 600) ? 'nashownotes.com' : 'noagendanotes.com'

      url = "http://#{show_num}.#{domain}"
      response = Net::HTTP.get_response(URI.parse(url))
      file_type = 'html'
      if ['301', '302'].include? response.code
        url = response['Location']
        if show_num >= Source::NEW_HTML_FORMAT_START
          url = url.gsub('html', 'opml')
          file_type = 'opml'
        end
        response = Net::HTTP.get_response(URI.parse(url))
      end
      puts url

      if response.code != '200'
        raise "#{response.code} received for #{url}"
      end

      text = response.body
    end

    is_new = show.nil?
    source = show&.source || Source.create!(
      text: text,
      show_id: show_num,
      file_type: file_type,
    )

    source.process_text! if is_new || reprocess
    source
  end
end
