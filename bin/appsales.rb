#!/usr/bin/env ruby
require 'appsales'
require 'date'

appsales = AppSales.new(ARGV[0], ARGV[1])

vendor_id = appsales.vendor_id
# app_ids = appsales.app_ids

# Review is [{:name, :url, :version, :date, :rating, :review}, ...]
# puts appsales.reviews(since: Date.new(2014, 1, 1))

# puts appsales.reviews(app_ids: app_ids[0], since: Date.new(2014, 1, 1))
# Gets reviews for one app, stop paging once 2 days old

# report = appsales.report(:daily, Date.new(2014, 1, 1))
# report = appsales.report(:weekly, Date.new(2014, 1, 1))
# reports contain all fields as listed in
# https://www.apple.com/itunesnews/docs/AppStoreReportingInstructions.pdf

# report.each do |sale|
#   puts sale
# end
