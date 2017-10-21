namespace :shownotes do
  desc "TODO"
  task fetch: :environment do
    require 'net/http'

    MINIMUM_SHOW = 490
    NA_RSS_URL = 'http://feed.nashownotes.com/'

    response = Net::HTTP.get_response(URI.parse(NA_RSS_URL))
    feed = Nokogiri::XML(response.body)

    # urls = feed.css('channel > item').map do |episode|
    #   url = episode.at_css('link').content
    #   url.include?('noagendanotes') ? url : nil
    # end.compact

    first_url = feed.at_css('channel > item > link').content
    last_show_number = Integer(first_url.match(/\d+/)[0])

    last_show_number.downto(MINIMUM_SHOW).each do |show_num|
      next if Show.exists?(show_num)

      url = "http://#{show_num}.noagendanotes.com"
      response = Net::HTTP.get_response(URI.parse(url))
      if ['301', '302'].include? response.code
        url = response['Location'].gsub('html', 'opml')
        response = Net::HTTP.get_response(URI.parse(url))
      end
      puts url

      if response.code != '200'
        puts "#{response.code} received for #{url}"
        next
      end

      text = response.body
      ActiveRecord::Base.transaction do
        Source.create!(
          text: text,
          file_type: 'opml',
          show_id: show_num
        )
      end
    end
  end
end
