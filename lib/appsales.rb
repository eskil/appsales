require 'mechanize'
require 'nokogiri'
require 'logger'

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
    @logger.info("Getting vendor id")
    login

    @mecha.get(@base_url) do |home_page|
      sales_page = @mecha.click(home_page.link_with(:text => /Sales and Trends/))
      @mecha.get('https://reportingitc2.apple.com/ligerService/PIANO/reports') do |piano|
        puts piano.content
      end
    end
    return 1
  end

  def app_ids
    @logger.info("Getting app ids")
    login

    return []
  end

  def reviews(args = {})
    @logger.info("Getting reviews")
    app_ids = args[:app_ids] or app_ids
    since = args[:since]
    puts app_ids
    puts since
  end

  def report(type, date)
    @logger.info("Getting reports")
    puts type, date
    []
  end

  protected

  def login(force = false)
    return if !force && logged_in?

    @logger.info("Logging in")
    @mecha.get(@base_url) do |page|
      login_result = page.form_with(:name => 'appleConnectForm') do |login|
        login.theAccountName = @username
        login.theAccountPW = @password
      end.submit

      raise 'login failed' if login_result.search("//a[text()='Sign Out']/@href").empty?
    end
  end

  def logged_in?
    result = false
    @mecha.get(@base_url) do |page|
      link = page.search("//a[text()='Sign Out']/@href")
      result = !link.empty?
    end
    @logger.info(result ? "Logged in" : "Not logged in")
    return result
  end

end
