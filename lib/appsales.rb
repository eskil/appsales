class AppSales
  def initialize(username, password)
    @username = username
    @password = password
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
end
