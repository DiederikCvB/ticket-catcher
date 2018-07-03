require 'capybara/cucumber'
require 'pry'
require_relative 'feature_helper'

After do
  if Capybara.current_driver == :chrome && !Capybara.current_url.start_with?('data:')
    page.execute_script <<-JAVASCRIPT
      localStorage.clear();
      sessionStorage.clear();
    JAVASCRIPT
  end
end


Before '@javascript' do
  page.driver.browser.manage.window.maximize
end