require "appsales/version"

Gem::Specification.new do |s|
  s.name        = 'appsales'
  s.version     = AppSales::VERSION
  s.date        = '2014-01-03'
  s.authors     = ["Eskil Olsen"]
  s.email       = 'eskil@eskil.org'
  s.homepage    = 'http://rubygems.org/gems/appsales'
  s.license     = 'MIT'

  s.summary     = "Get Appsales info for your iOS apps"
  s.description = "Reads, parses and scrapes iOS app sales info and reviews."

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ["lib"]
end