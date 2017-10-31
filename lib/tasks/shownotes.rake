namespace :shownotes do
  desc "TODO"
  task fetch: :environment do
    require 'net/http'

    MINIMUM_SHOW = 489 # Before that the URLs are not consistent
    NA_RSS_URL = 'http://feed.nashownotes.com/'

    response = Net::HTTP.get_response(URI.parse(NA_RSS_URL))
    feed = Nokogiri::XML(response.body)

    first_url = feed.at_css('channel > item > link').content
    last_show_number = Integer(first_url.match(/\d+/)[0])

    last_show_number.downto(MINIMUM_SHOW).each do |show_num|
      begin
        puts show_num
        Source.process!(show_num, true)
      rescue => e
        raise e if Rails.env.development? && show_num != 505
        error = -> (msg) { puts msg; Rails.logger.error(msg) }
        error["Problem saving show #{show_num}"]
        error[e.message]
        error[e.backtrace.join("\n")]
      end
    end
  end
end
