require 'yaml/store'
require 'time'
require 'logger'

$current_data = Hash.new()
$logger = Logger.new('error.log', 'monthly')
$logger.level = Logger::WARN
$logger.warn("Program is running!")


Given "I'm on the homepage" do
  page.visit('/')
  expect(page).to have_css('div#_evidon-banner,div#_evidon_banner',wait:10)
end


When /^I accept cookies$/ do
  if page.has_css?('div#_evidon-banner')
    within('div#_evidon-banner') do
      click_button('_evidon-accept-button')
    end
  else 
    within('div#_evidon_banner') do
      click_button('_evidon-accept-button')
    end
  end
end

Then /^I should be on the homepage with an account button$/ do
  #expect(page).to have_button('Account')
  #expect(page).to have_button('Mijn account')
  expect(page).to have_css('span', text: 'Mijn Account')
end

And /^I open the account page$/ do
  expect(page).to have_css('span', text: 'Mijn Account')
  startval = page.find_all('div').count
  #click_button('Account')
  #click_button('Mijn account')
  find('span', text: 'Mijn Account').click
  expect(page).to have_css('.toplinks__button--account')
end

Then /^I should see the account screen$/ do
  within('div.header__desktop') {
    expect(page).to have_css('button.toplinks__button--account', wait:20)
  }
  within('div.loginregister--myaccount') {
    expect(page).to have_button('Inloggen')
  }
end

And /^I choose "inloggen"$/ do
    find('div.loginregister--myaccount').click_button('Inloggen')
    expect(page).not_to have_css('div.blockcontent')
    expect(page).to have_css('div.loginregister--myaccount', wait: 20)
end


Then(/^I enter account details$/) do
  find('#login__email').set'diederik.saxofoon@gmail.com'
  find('#login__password').set'Vriendje'
  click_button('Inloggen')
end


Then(/^I should be logged in$/) do
  expect(page).to have_css('div.avatar__greeting', text: 'Welkom')
end

When(/^I press Start$/) do
  press_start
end

def press_start
  page.find('.discover--small__submit').click
  expect(page).to have_css('h1.contentheading--pageheading')
end

Then(/^I should extract ticket data for music$/) do
  ticket_explorer
end

def load_data_base
  # load previous data
  ticketBase = YAML::Store.new('store.yml')
  $current_data = ticketBase.transaction do 
    ticketBase[:data] 
    ticketBase[:data] ||= Hash.new
  end
  $pointer = ticketBase.transaction do
    ticketBase[:pointer]
    ticketBase[:pointer] ||= [0,0]
  end
  $errors = ticketBase.transaction do
    ticketBase[:errors]
    ticketBase[:errors] ||= Hash.new
  end
  return ticketBase
end

def ticket_explorer
  ticketBase = load_data_base
  open_filters
  retry_errors(ticketBase)
  resume_ticket_search(ticketBase)
end

def retry_errors(ticketBase)
  months = $errors[:month].clone
  months.each do |er|
    firstTime = er[0]    
    month_error = er[1]
    $errors[:month].delete(firstTime)
    artist = ''
    begin
      open_filters
      within('#search-filter-attraction') {
        artist = select_filter_option(month_error[0])
      }
      within('#search-filter-date') {
        month_name = select_filter_option(month_error[1])
      }
      browse_ticket_list(artist,month_error[1])
      store_data(ticketBase)
    rescue StandardError => e
      $logger.error('error retry failed: ' + month_error[0] + '_month:' + month_error[1].to_s)
      $logger.error(e)
      $errors[:month] ||= Hash.new()
      $errors[:month][firstTime] = [month_error[0],month_error[1]]
    ensure
      store_data(ticketBase)
      if !page.has_css?('#event-lists')
        page.go_back
      end
    end    
  end
end

def resume_ticket_search(ticketBase)
  artist_list = find('#search-filter-attraction').find_all('li')
  artist_len = artist_list.length
  puts artist_len
  artist_start = ($pointer[0] == 0? artist_len-1 : $pointer[0]+1)
  puts artist_start
  artist_i =  (1..artist_start).to_a.reverse + (artist_start+1..artist_len-1).to_a.reverse
  puts artist_i
  artist_i.each do |i|
    $pointer[0] = i
    artist = ''
    open_filters
    within('#search-filter-attraction') {
      puts i
      artist = select_filter_option(i)
      puts artist
    }
    cycle_month(artist,ticketBase)
  end
  $pointer[0] = 0
end

def store_data(ticketBase)
  ticketBase.transaction do
    ticketBase[:data] = $current_data
    ticketBase[:pointer] = $pointer
    ticketBase[:errors] = $errors
    ticketBase.commit
  end  
end

def open_filters
  if !page.has_css?('.searchfilter__holder:not(.is-closed)',wait: 0.5) or page.has_css?('.searchfilter__holder.is-closed', wait: 2)
    page.find('.searchfilter__holder.is-closed').click
    expect(page).to have_css('.searchfilter__holder:not(.is-closed)',wait: 10)
    expect(find('#search-filter-date')).to have_css('ul.searchfilter--checklist')
  end
end

def select_filter_option(i)
  page.find('.searchfilter--checklist__link', match: :first).click
  page.find('div.searchfilter__filterbox')
  expect(page).to have_css('li:nth-of-type(1) a.is-active')
  expect(page).to have_css('.searchfilter--checklist__link.is-active',count: 1)
  opt_list = page.find_all('li') 
  if i.is_a? Integer
    opt_list[i].find('a').click
  elsif i.respond_to? :to_str #case mont_error retry
    page.find('.searchfilter--checklist__link', text: i).click    
  else
    puts "PANIC" + i
  end
    expect(page).to have_css('li:nth-of-type(1) a:not(.is-active)')
    expect(page).to have_css('.searchfilter--checklist__link.is-active',count: 1)
    return find('.searchfilter--checklist__link.is-active',count: 1).text
end


def cycle_month(artist,ticketBase)
  month_list = find('#search-filter-date').find_all('li')
  month_len = month_list.length
  month_start = $pointer[1] == 0? month_len-1 : $pointer[1]+1
  month_i = (1..month_start).to_a.reverse + (month_start+1..month_len-1).to_a.reverse
  puts month_i
  month_i.each do |i|
    month_name = ''
    puts 'monthnr: '+ i.to_s
    $pointer[1] = i
    open_filters
    begin
      within('#search-filter-date') {
        month_name = select_filter_option(i)
      }
      browse_ticket_list(artist,month_name)
      store_data(ticketBase)
    rescue NoMethodError => e
      $logger.error('monthlist failed: ' + artist)
      $logger.error(e)
      $errors[:month_list] ||= Hash.new()
      $errors[:month_list][Time.new()] = [artist]     
    end
  end
  $pointer[1] = 0
end

def browse_ticket_list(artist,month)
  begin
    if page.has_css?('ul.table__row--event', wait: 0.5) or page.has_no_css?('p.table__row--noresults__message', wait: 0.5)  
      paginate_to_end
      extract_ticket_list(artist)
      while paginate_prev
        extract_ticket_list(artist)
      end
    end
  rescue StandardError => e
    $logger.error('ticketbrowsing failed: ' + artist + '_month:' + month.to_s)
    $logger.error(e)
    $errors[:month] ||= Hash.new()
    $errors[:month][Time.new()] = [artist,month]
  ensure
    if !page.has_css?('#event-lists')
      page.go_back
    end
  end  
end

def paginate_to_end
  if page.has_css?('div.pagination--search:not(.hide)')
    within('div.pagination--search:not(.hide)'){
      while page.has_no_css?('.pagination__lastitem span.pagination__next.is-disabled')
        last = find('.pagination__pagenumberlist').find_all('.pagination__pagenumber').last.find('a.pagination__link').text
        find('.pagination__pagenumberlist').find_all('li.pagination__pagenumber').last.click
        expect(page).to have_css('.pagination__pagenumber span', text: last)
      end
    }
  end
end

def paginate_prev
  if page.has_css?('div.pagination--search:not(.hide)')
    within('div.pagination--search:not(.hide)'){
      if page.has_no_css?('.pagination__firstitem span.pagination__prev.is-disabled')
        prev = find('.pagination__pagenumber span.performerPagingSelected').text
        find('.pagination__firstitem').click
        expect(page).to have_css('.pagination__pagenumber a', text: prev)
        return true
      end
    }
  end
  return false
end

def extract_ticket_list(artist)
  ticket_num = find('#event-lists').find_all('ul.table__row--event  ').length
  puts ticket_num
  (1..ticket_num).to_a.reverse.each do |ticketrow|
    expect(page).to have_css('span.discover--small__submit__text')
    event = find('#event-lists').find('ul:nth-of-type('+ticketrow.to_s+')')
    if event.has_css?('div.status')
      link = event.find('a.link--viewdates')[:href]
      page.visit(link)
    else
      event.find('div.table__cell__body--availability').find('a.button--buy.roundedButton').click
    end
    checkout_ticket(artist)
  end
end

def checkout_ticket(artist)
  window = page.driver.browser.window_handles
    #feature close
  if window.size > 1
    closeNewTabs
    #   manage_feature_event(window)?
  else
    extract_ticket_details(artist)
  end
end

def extract_ticket_details(artist)
  sleep 0.3
  page.evaluate_script("window.location.reload()") 
  find('div.eventinfo__main__info').click
#extract data
  if !page.has_css?('div.special_info_content__nav__info__text[data-component="modal-event-information-venue"]')
    puts artist + ' has incomplete ticket info'
    page.go_back
    return
  end
  location = find('div.special_info_content__nav__info__text[data-component="modal-event-information-venue"]').text
  time = Time.parse(find('div.special_info_content__nav__info__text[data-component="modal-event-information-date-time"]').text)
  puts time
  page.find('div.modal__header').find('button.cButton').click
  #entry[0] = time#
  #entry[1] = artist#
  #entry[2] = ticket_name#
  #entry[3] = location#
  #entry[4] = price#
  #entry[5] = soldout_type
  #entry[6] = soldout_date
  #entry[7] = first_seen_date
  concert_id = time.to_s+'_'+artist
  begin
    handle_ticket_cases(time,artist,location,concert_id)
  rescue StandardError => e
    $logger.error('Individual ticket')
    $logger.error(concert_id)
    $logger.error(e)
    $errors[:concert] ||= Hash.new
    $errors[:concert][Time.new()] = [URI.parse(current_url).to_s, artist]
  end
  page.go_back
end

def handle_ticket_cases(time,artist,location, concert_id)
  if $current_data.key?(concert_id)
    #case already in database
    #only check sold-out etc
    if page.has_css?('div.error--ntf')
      if page.has_css?('div.error--ntf span h3', text: /d*s*uitverkochtd*s*/)
        $current_data[concert_id].keys.each do |key|
          if $current_data[concert_id][key][6] == nil or $current_data[concert_id][key][5] != 'fully'
            $current_data[concert_id][key][5] = 'fully'
            $current_data[concert_id][key][6] = Time.new()
          end
        end
      elsif page.has_css?('div.error--ntf span h3', text: /d*s*\(online\)d*s*/)
      # check for outsold online, mark it special case?
        $current_data[concert_id].keys.each do |key|
          if $current_data[concert_id][key][6] == nil or $current_data[concert_id][key][5] == 'temp'
            $current_data[concert_id][key][5] = 'online'
            $current_data[concert_id][key][6] = Time.new()
          end
        end
      elsif page.has_css?('div.error--ntf span h3', text: /d*s*op dit moment geen ticketsd*s*/)
      # check for outsold temporary, mark it special case?
        $current_data[concert_id].keys.each do |key|
          if $current_data[concert_id][key][6] == nil
            $current_data[concert_id][key][5] = 'temp'
            $current_data[concert_id][key][6] = Time.new()
          end
        end      
      else 
        puts 'unexplained: '+ concert_id
      # check for outsold presale, mark it special case?
      #$current_data[concert_id][key][5] = 'pre-sale'
      end 
    elsif page.has_css?('.mainContent__unavailableModule')
      # check for canceled
      $current_data[concert_id].keys.each do |key|
        $current_data[concert_id][key][6] = nil
        $current_data[concert_id][key][5] = 'canceled'
      end 
    else
      #check soldout after selecting for each ticket
      check_ticket_opt_soldout
    end
  else
    #if new entry
    if page.has_css?('#ticketChoose', wait: 0.5) and page.has_no_css?('div.error--ntf')
      $current_data[concert_id] ||= Hash.new
      extract_new_ticket_options(time,artist,location, concert_id)
      check_ticket_opt_soldout
    end
  end
end

def check_ticket_opt_soldout
  switch_to_simple
  expect(page).to have_css('li.price-type')
  ticket_options = page.find_all('li.price-type')
  ticket_options.each do |ticket|
    ticket_id = ticket[:id]
    expect(page).to have_css("li##{ticket_id}")
    select('2', from: "#{ticket_id}_tixnum")
    find('#choosePriceLocation_LookForTicketsButton').click()
    if page.has_css?('#recaptcha')
      page.find('.btn_close').click
    elsif page.has_css?('div.error--ntf span h3', text: /d*s*er zijn geen tickets beschikbaard*s*/)
      $current_data[concert_id][key][5] = 'fully'
      $current_data[concert_id][key][6] = Time.new()
    else
      page.go_back
    end
    select('0', from: "#{ticket_id}_tixnum")
  end 
end

def switch_to_simple
  if page.has_css?('li.price-type')
    return
  else
    expect(page).to have_css('div')
    page.find_all('div', match: :first).each do |el|
      puts el[:class]
    end
    if page.has_css?('div.edpcontent__ticketpriceinfo')
      find('div.edpcontent__ticketpriceinfo').find('button.cButton').click
    else
      x = 350
      y = 31
      puts x
      page.has_css?('li.price-type')
      page.driver.browser.action.move_to(find('div.switchToEDPContainer').native, x, -y ).click.perform
      expect(page).to have_css('li.price-type')
    end
  end 
end

def extract_new_ticket_options(time, artist, location, concert_id)
  expect(page).to have_css('li.price-type')
  ticket_options = page.find_all('li.price-type')
  puts 'tickets: ' + ticket_options.length.to_s
  ticket_options.each do |ticket|
    ticket_entry = Array.new(8)
    ticket_id = ticket[:id]
    expect(page).to have_css("li##{ticket_id}")
    expect(find("li##{ticket_id}").find('div.priceBox')).to have_css("strong", wait:10)
    ticket_name = page.find("##{ticket_id}_desc").text.strip.gsub(/[^0-9A-Za-z]/, '')
    ticket_price = page.find("li##{ticket_id}").find('div.priceBox').find("strong", wait:10).text
    if ticket_price[-1] == '-'
      ticket_price = ticket_price.delete("^0-9").to_i
    else
      ticket_price = ticket_price.delete("^0-9").to_i/100.0
    end
    ticket_entry[0] = time
    ticket_entry[1] = artist   
    ticket_entry[3] = location
#new
    ticket_entry[2] = ticket_name
    ticket_entry[4] = ticket_price
    ticket_entry[7] = Time.new()
    puts ticket_name
    $current_data[concert_id][ticket_name] = ticket_entry
  end
end

def closeNewTabs
  window = page.driver.browser.window_handles
  while window.size > 1 
    page.driver.browser.switch_to.window(window.last)
    page.driver.browser.close
    page.driver.browser.switch_to.window(window.first)
    window = page.driver.browser.window_handles    
    end
end

def manage_feature_event(window)
  page.driver.browser.switch_to.window(window.last)
  expect(page).not_to have_css('#event-lists')
  expect(page).not_to have_css('p', text: 'Pagina wordt geladen...', wait:10)
  expect(page).to have_css('a', text: 'REGULIERE TICKETS', match: :first, wait: 10)
  page.find('a', text: 'REGULIERE TICKETS', match: :first, wait: 10).click
  window = page.driver.browser.window_handles
  page.driver.browser.switch_to.window(window.last)
end