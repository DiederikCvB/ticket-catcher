require 'rspec'
require_relative 'spec_helper'
require 'capybara/rspec'
require 'capybara'
require 'capybara/dsl'
require 'selenium/webdriver'

Capybara.register_driver :headless_chrome_docker do |app|
  caps = Selenium::WebDriver::Remote::Capabilities.chrome(
    "chromeOptions" => {
      'args' => ['headless', 'disable-gpu', 'no-sandbox']
    }
  )
  Capybara::Selenium::Driver.new(
    app,
    url:'http://chrome:4444/wd/hub',
    desired_capabilities: caps
  )
end

Capybara.register_driver :headless_chrome do |app|
  caps = Selenium::WebDriver::Remote::Capabilities.chrome(
    "chromeOptions" => {
      'args' => ['headless', 'disable-gpu']
    }
  )
  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    desired_capabilities: caps
  )
end

Capybara.register_driver :headless_chromium do |app|
  caps = Selenium::WebDriver::Remote::Capabilities.chrome(
    "chromeOptions" => {
      'binary' => '/Applications/Chromium.app/Contents/MacOS/Chromium',
      'args' => ['headless', 'disable-gpu']
    }
  )
  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    desired_capabilities: caps
  )
end

Capybara.register_driver :chrome do |app|
  args = ["--start-fullscreen", "--disable-infobars"
    #, "--user-data-dir=/Users/diederik/Documents/acceptance_specs/chromeuser"
  ]
  preferences = {
    "profile.default_content_settings.popups" => 2   
  }
  
  caps = Selenium::WebDriver::Remote::Capabilities.chrome( 
    'chromeOptions' => {
      'prefs' => preferences 
    } 
  )
  Capybara::Selenium::Driver.new(
    app, {:browser => :chrome,
    :args => args,
    :desired_capabilities  => caps
    }
  )
end

# Capybara.register_driver :firefox do |app|
#   Capybara::Selenium::Driver.new(app, browser: :firefox)
# end

# Poltergeist
#require 'capybara/poltergeist'
#Capybara.register_driver :headless_chrome_poltergeist do |app|
  #options = {
    #js_errors: false,
    #debug: false,
    #window_size: [1280, 968],
    #phantomjs_options: %w(--debug=no
                          #--load-images=no
                          #--ignore-ssl-errors=no
                          #--ssl-protocol=TLSv1
                          #--local-to-remote-url-access=no)
  #}
  #Capybara::Poltergeist::Driver.new(app, options)
#end

Capybara.configure do |config|
  config.run_server = true
  config.default_driver = ENV.fetch('DRIVER', 'chrome').to_sym
  config.app_host = ENV.fetch('ENDPOINT', 'http://ticketmaster.nl')
  config.default_max_wait_time = 5
end
