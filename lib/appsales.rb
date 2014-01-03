require 'net/https'
require 'nokogiri'


class AppSales
  def initialize(username, password)
    @username = username
    @password = password
    puts get_login_form
  end

  def vendor_id
  end

  def app_ids
    [1]
  end

  def reviews(args = {})
    app_ids = args[:app_ids] or app_ids
    since = args[:since]
    puts app_ids
    puts since
  end

  def report(type, date)
    puts type, date
    []
  end

  protected

  def get_login_form
    url = URI.parse('https://itunesconnect.apple.com')

    (0..3).each do |limit|
      raise Exception, 'Too many HTTP redirects' if limit == 3

      response = Net::HTTP.start(url.host, use_ssl: true) do |http|
        http.get url.request_uri
      end

      case response
      when Net::HTTPRedirection
        new_url = URI.parse(response['location'])
        if new_url.host
          url = new_url
        else
          url.path = new_url.path
        end
      when Net::HTTPSuccess
        doc = Nokogiri::HTML(response.body)
        form = doc.xpath('//form[@name="appleConnectForm"]')
        action = form[0]['action']
        ...
      else
        # response code isn't a 200; raise an exception
        response.error!
      end
    end
  end
end
