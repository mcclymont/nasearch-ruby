module Loaders::OPML
  def strip_html(input)
    text = CGI.unescapeHTML(input)
    if text.start_with?('<')
      text = Nokogiri::XML(text).children[0].text
    end
    text.strip
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

  TOLERATE_NO_CLIPS = Set.new([
    1018, # Has clips but they aren't nested like they should be https://1018.noagendanotes.com
    889, # Christmas Special
    850, # 200.8 Re-Redux
  ])

  def process_text!
    ActiveRecord::Base.transaction do
      set_show! unless show.present?
      delete_notes!

      xml = Nokogiri::XML(text)
      start = xml.at_xpath("/opml/body/outline[@type='tabs']")

      shownotes = start.xpath("./outline[@text='Shownotes']/outline")
      clips = start.xpath("./outline[@text='CLIPS & DOCS']/outline | ./outline[@text='Clips & Docs']/outline | ./outline[@text='Clips and Stuff']/outline | ./outline[@text='Clips Docs & Stuff']/outline | ./outline[@text='Clips and Docs']/outline")

      if shownotes.empty? && clips.empty?
        raise 'No shownotes or clips!'
      elsif shownotes.empty?
        raise 'No shownotes!'
      elsif clips.empty?
        raise 'No clips!' unless TOLERATE_NO_CLIPS.include?(show.id)
      end

      process_topics(shownotes, false)
      process_topics(clips,     true)

      # Various examples of this happening: 945, 946, 947 only have Art in Clips. 976 might be malformed.
      puts "Warning: Only 1 clip found for show #{show_id}" if clips.length == 1
    end
  end

  def process_topics(nodes, are_clips)
    nodes.each do |topic_node|
      next if topic_node['text'].start_with?('<')

      topic = topic_node['text']
      notes = topic_node.xpath('outline')

      if !are_clips && notes.all? { |note| note.children.empty? && !note['text'].starts_with?('<') }
        # We aren't going to get a separate title and then further
        # children nodes with the actual text
        # This is the text - and we didn't get a title node.
        notes = [topic_node]
      end

      notes.each do |note_node|
        title = strip_html(note_node['text'])
        next if title.match? /^[ ]*-+$/ # Some are just '------------' (and some start with a space)

        note = show.notes.new(
          topic: topic,
          title: title
        )

        children = note_node.children
        children = [note_node] if children.empty? # Happens for clips

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
            text = "<a href=\"#{url}\">#{text}</a>"
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
