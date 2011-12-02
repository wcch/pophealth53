source 'http://rubygems.org'

gem 'rails', '3.1.0'
# locked to 1.3.3 to resolve annoying warning 'already initialized constant WFKV_'
gem 'rack' , '1.3.3'

gem 'quality-measure-engine', :path => '../quality-measure-engine/'
#gem 'quality-measure-engine', :git => 'http://github.com/pophealth/quality-measure-engine.git', :branch => 'develop'
gem 'nokogiri'
gem 'rubyzip'

gem "will_paginate"
gem 'json', :platforms => :jruby
# these are all tied to 1.3.1 because bson 1.4.1 was yanked.  To get bundler to be happy we need to force 1.3.1 to cause the downgrade
gem "mongo", "1.3.1"
gem "bson", "1.3.1"
gem 'bson_ext',"1.3.1",  :platforms => :mri
gem "mongoid"
gem 'devise'
gem 'foreman'
gem 'pry'
gem 'formtastic'
gem 'cancan'

# Windows doesn't have syslog, so need a gem to log to EventLog instead
gem 'win32-eventlog', :platforms => [:mswin, :mingw]

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails', "  ~> 3.1.0"
  gem 'coffee-rails', "~> 3.1.0"
  gem 'uglifier'
end

group :test, :develop do
  # gem "rspec-rails"
  # Pretty printed test output
  gem "unicorn"
  gem 'turn', :require => false
  gem 'cover_me'
  gem 'factory_girl'
  gem 'minitest'
  gem 'mocha', :require => false

end

group :production do
  gem 'therubyracer'
end

gem 'jquery-rails'

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'ruby-debug19', :require => 'ruby-debug'

