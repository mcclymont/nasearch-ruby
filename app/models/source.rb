class Source < ApplicationRecord
  belongs_to :show

  def strip_html(input)
    text = CGI.unescapeHTML(input)
    if text.start_with?('<')
      text = Nokogiri::XML(text).children[0].text
    end
    text
  end

  def process_text!
    ActiveRecord::Base.transaction do
      show.notes.destroy_all

      xml = Nokogiri::XML(text)
      start = xml.at_xpath("/opml/body/outline[@type='tabs']")

      shownotes = start.xpath("outline[@text='Shownotes']/outline")
      clips = start.xpath("outline[@text='CLIPS & DOCS']/outline")

      (shownotes + clips).each do |topic_node|
        puts topic_node['text']
        next if topic_node['text'].start_with?('<')

        topic = topic_node['text']
        topic_node.xpath('outline').each do |note_node|
          note = show.notes.new(
            topic: topic,
            title: strip_html(note_node['text'])
          )

          children = note_node.children

          children = [note_node] if children.empty?

          entries = children.map do |entry_node|
            text = entry_node['text']
            next if text.blank?
            next if [
              '").addClass(n).attr(',
              '\n {{ more.more_rank',
              '-1)r&&r.push(o);else'
            ].any? { |str| text.starts_with? str }

            text = strip_html(text)

            attrs = {text: text}
            if entry_node.key?('url')
              url = entry_node['url']
              if attrs[:text].blank?
                attrs[:text] = File.basename(URI.parse(url).path)
              end
              attrs.merge!(url: url)
            end

            next if attrs[:text].blank?

            attrs
          end.compact

          if entries.any?
            urls, texts = entries.partition { |h| h.key? :url }

            if note.title.blank? && urls.length == 1
              url = urls.first[:url]
              extension = File.extname(url)
              note.title = "File: #{extension[1..-1]}" unless extension.blank?
            end

            note.save!
            note.text_entries.create!(texts)
            note.url_entries.create!(urls)
          end
        end
      end
    end
  end
end
