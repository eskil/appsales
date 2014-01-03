# encoding: utf-8
require 'net/http'
require 'mechanize'
require 'nokogiri'
require 'json'
require 'logger'
require 'appsales/stores'

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
    login do |home_page|
      sales_page = @mecha.click(home_page.link_with(:text => /Sales and Trends/))
      @mecha.get('https://reportingitc2.apple.com/ligerService/PIANO/reports') do |piano|
        j = JSON.parse(piano.content)
        return j['contents'][0]['reports'][0]['vendors'][0]['id']
      end
    end

    return nil
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

    return result
  end

  def reviews(args = {})
    @logger.info("Getting reviews")
    @logger.info("Getting reviews #{STORE_IDS}")
    apps = args[:app_ids] ? [args[:app_ids]] : self.app_ids.keys

    since = args[:since]
    apps.each do |app_id|
      STORE_IDS.each do |country, store_id|
        page = 1

        uri = URI.parse("https://itunes.apple.com/WebObjects/MZStore.woa/wa/customerReviews?s=#{store_id}&id=#{app_id}&displayable-kind=11&page=#{page}&sort=4")

        (0..3).each do |limit|
          raise Exception, 'Too many HTTP redirects' if limit == 3

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
            reviews = doc.xpath("//div[@class='customer-review']")
            puts "#{app_id} reviews in #{country} #{reviews.count}"
            reviews.each do |review|
              reviewer = review.search("//a[@class='reviews']").text()
              content = review.xpath("//p[@class='content']")
              puts "#{reviewer} #{content}"
            end
            break
          else
            response.error!
          end
        end
      end
    end
    puts app_ids
    puts since
  end

  def report(type, date)
    @logger.info("Getting reports")
    puts type, date
    []
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
