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

  # Try n times to load the url
  def load_url(url, limit = 3)
    raise Exception, 'Too many HTTP redirects' if limit == 0

    url = (url.is_a? URI) ? url : URI.parse(url)

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
      load_url(url, limit - 1)
    when Net::HTTPSuccess
      return response.body
    else
      response.error!
    end
  end

  def get_login_form(url = 'https://itunesconnect.apple.com')
    page = load_url(url)
    doc = Nokogiri::HTML(page)
    form = doc.xpath('//form[@name="appleConnectForm"]')
    action = form[0]['action']
    puts action
  end
end
