# AppSales


This is a ruby gem to scrape iTunesConnect for app sales info and
reviews. It's based on https://github.com/omz/AppSales-Mobile.

```ruby
require 'appsales'
require 'date'

username = 'youritunesconnectusername'
password = 'youritunesconnectpassword'

appsales = AppSales.new(username, password)

# Scrape itunes for vendor id and app ids.
puts appsales.vendor_id
puts appsales.app_ids

# Get the daily sales info for Feb 6th.
puts appsales.report(:daily, Date.new(2014, 02, 06))

# Get the weekly sales info for week ending Feb 16th
puts appsales.report(:daily, Date.new(2014, 02, 16))
```