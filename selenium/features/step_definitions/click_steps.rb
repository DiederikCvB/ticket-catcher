And /^I click "(.*)"$/ do |locator|
  expect(page).to have_selector(:link_or_button, text: locator, match: :one)
  click_on(locator)
end

And(/^I go back$/) do
  page.go_back
end