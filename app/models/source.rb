class Source < ApplicationRecord
  belongs_to :show
  before_validation :set_show!

  def inspect
    "#<Source show_id: #{show_id} file_type: #{file_type}>"
  end

  def strip_html(input)
    text = CGI.unescapeHTML(input)
    if text.start_with?('<')
      text = Nokogiri::XML(text).children[0].text
    end
    text
  end

  def extract_html(input)
    text = CGI.unescapeHTML(input)
    Nokogiri::XML(text).children[0]
  end

  def extract_title
    xml = Nokogiri::XML(text)
    unless xml.errors.empty?
      return puts "Nokogiri errors for episode #{show_id}"
    end

    title = xml.at_css('head title').content
    if show_id == 726
      'Weather Whiplash' # Quotes weren't closed
    elsif show_id == 589
      nil # Not available
    else
      CGI.unescapeHTML(title).match(/"(.*)"/)[1]
    end
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

  def process_text!
    ActiveRecord::Base.transaction do
      set_show! unless show.present?
      delete_notes!

      xml = Nokogiri::XML(text)
      start = xml.at_xpath("/opml/body/outline[@type='tabs']")

      shownotes = start.xpath("outline[@text='Shownotes']/outline")
      clips = start.xpath("outline[@text='CLIPS & DOCS']/outline")

      (shownotes + clips).each do |topic_node|
        next if topic_node['text'].start_with?('<')

        topic = topic_node['text']
        notes = topic_node.xpath('outline')

        if notes.all? { |note| note.children.empty? && !note['text'].starts_with?('<') }
          # We aren't going to get a separate title and then further
          # children nodes with the actual text
          # This is the text - and we didn't get a title node.
          notes = [topic_node]
        end

        notes.each do |note_node|
          note = show.notes.new(
            topic: topic,
            title: strip_html(note_node['text'])
          )

          children = note_node.children

          children = [note_node] if children.empty?

          urls = []
          entries = children.map do |entry_node|
            text = entry_node['text']
            next if text.blank?
            next if [
              '").addClass(n).attr(',
              '\n {{ more.more_rank',
              '-1)r&&r.push(o);else'
            ].any? { |str| text.starts_with? str }

            if entry_node.key?('url')
              url = entry_node['url']
              if text.blank?
                text = File.basename(URI.parse(url).path)
              end
              urls << {text: text, url: url}
              text = "<a href='#{url}'>#{text}</a>"
            end

            next if text.blank?

            text
          end.compact

          if entries.any? || urls.any?
            note.text = entries.join("\n")

            if note.title.blank? && urls.length == 1
              url = urls.first[:url]
              extension = File.extname(url)
              note.title = "File: #{extension[1..-1]}" unless extension.blank?
            end

            note.save!
            note.url_entries.create!(urls)
          end
        end
      end
    end
  end
end
