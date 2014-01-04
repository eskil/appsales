# encoding: utf-8
require 'net/http'
require 'mechanize'
require 'nokogiri'
require 'json'
require 'logger'
require 'appsales/stores'
require 'zlib'
require 'csv'

class AppSales
  def initialize(username, password)
    @username = username
    @password = password
    @mecha = Mechanize.new

    @base_url = 'https://itunesconnect.apple.com'
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO
  end

  def vendor_id
    @vendor_id ||= login do |home_page|
      sales_page = @mecha.click(home_page.link_with(:text => /Sales and Trends/))
      @mecha.get('https://reportingitc2.apple.com/ligerService/PIANO/reports') do |piano|
        j = JSON.parse(piano.content)
        return j['contents'][0]['reports'][0]['vendors'][0]['id']
      end
    end
  end

  def app_ids
    result = {}
    login do |home_page|
      apps_page = @mecha.click(home_page.link_with(:text => /Manage Your Apps/))
      all_page = @mecha.click(apps_page.link_with(:text => /See All/))
      apps = all_page.search("div.resultList table")
      apps.xpath("tr[not(contains(@class, 'column-headers'))]").each do |row|
        cells = row.xpath("td")
        app_name = cells[0].search("a")[0].text.strip()
        version = cells[2].search("p")[0].text.strip()
        app_id = cells[4].search("p")[0].text.strip()
        result[app_id] =  {name: app_name, version: version}
      end
    end
    @app_ids = result
    return result
  end

  def reviews(args = {})
    result = {}
    failed_stores = []

    @logger.info("Getting reviews")
    @logger.info("Getting reviews #{STORE_IDS}")
    apps = args[:app_ids] ? [args[:app_ids]] : self.app_ids.keys

    since = args[:since]
    apps.each do |app_id|
      STORE_IDS.each do |country, store_id|
        page = 1

        uri = URI.parse("https://itunes.apple.com/WebObjects/MZStore.woa/wa/customerReviews?s=#{store_id}&id=#{app_id}&displayable-kind=11&page=#{page}&sort=4")

        (0..3).each do |limit|
          raise Exception, 'Too many HTTP redirects or attempts' if limit == 3

          @logger.info("#{limit}: #{uri}")
          response = Net::HTTP.start(uri.host, use_ssl: true) do |http|
            http.get uri.request_uri, {
              'User-Agent' => "iTunes/10.1.1 (Macintosh; Intel Mac OS X 10.6.5) AppleWebKit/533.19.4",
              "X-Apple-Store-Front" => "#{store_id}-1,12",
            }
          end

          case response
          when Net::HTTPRedirection
            new_uri = URI.parse(response['location'])
            if new_uri.host
              uri = new_uri
            else
              uri.path = new_uri.path
            end
          when Net::HTTPSuccess
            doc = Nokogiri::HTML(response.body)
            doc.search("//div[@class='customer-review']").each do |review|
              reviewer = review.search("a.reviewer").text.strip
              url = review.search("a.reviewer/@href").text.strip
              content = review.search("p.content").text.strip
              rating = review.search("div.rating/@aria-label").text.to_i
              result[store_id] ||= []
              result[store_id] << {reviewer: reviewer, url: url, rating: rating, review: content}
            end
            break
          else
            failed_stores << store_id
            break
            # response.error!
          end
        end
      end
    end

    return result, failed_stores
  end

  def report(type, date)
    result = []

    @logger.info("Getting reports")
    uri = URI.parse('https://reportingitc.apple.com/autoingestion.tft')

    (0..3).each do |limit|
      raise Exception, 'Too many HTTP redirects or attempts' if limit == 3

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.set_debug_output($stdout)

      data = {
        USERNAME: @username,
        PASSWORD: @password,
        VNDNUMBER: self.vendor_id,
        TYPEOFREPORT: 'Sales',
        DATETYPE: type,
        REPORTTYPE: 'Summary',
        REPORTDATE: date.strftime('%Y%m%d')
      }

      request = Net::HTTP::Post.new(uri.request_uri)
      request['User-Agent'] = 'java/1.6.0_26'
      request.set_form_data(data)

      response = http.request(request)

      case response
      when Net::HTTPRedirection
        new_uri = URI.parse(response['location'])
        if new_uri.host
          uri = new_uri
        else
          uri.path = new_uri.path
        end
      when Net::HTTPSuccess
        gz = Zlib::GzipReader.new(StringIO.new(response.body))
        blob = gz.read
        csv = CSV.parse(blob, {col_sep: "\t"})
        keys = csv.shift.map{|key| key.downcase.gsub(' ', '_')}
        csv.each do |line|
          result << Hash[keys.zip(line)]
        end
        break
      else
        response.error!
      end
    end

    return result
  end

  protected

  def login
    @logger.info("Fetching homepage")
    @mecha.get(@base_url) do |page|
      signout_link = page.search("//a[text()='Sign Out']/@href")
      if signout_link.empty?
        @logger.info("Logging in")
        login_result = page.form_with(:name => 'appleConnectForm') do |login|
          login.theAccountName = @username
          login.theAccountPW = @password
        end.submit

        raise 'login failed' if login_result.search("//a[text()='Sign Out']/@href").empty?

        yield login_result
      else
        yield page
      end
    end
  end
end
