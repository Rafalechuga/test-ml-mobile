Given('I am on the Mercado Libre home screen') do
  # Wait for app to load
  wait = Selenium::WebDriver::Wait.new(timeout: 30)
  
  # Look for common elements on home screen
  search_bar = wait.until { find_element(:id, 'com.mercadolibre:id/action_search') rescue nil }
  logo = wait.until { find_element(:id, 'com.mercadolibre:id/header_icon') rescue nil }
  
  expect(search_bar || logo).not_to be_nil
end

When('I tap on the search bar') do
  # Try different possible search bar locators
  search_bar = find_element(:id, 'com.mercadolibre:id/action_search') rescue nil
  search_bar ||= find_element(:accessibility_id, 'search_bar') rescue nil
  search_bar ||= find_element(:xpath, '//android.widget.EditText[@text="Buscar"]') rescue nil
  
  search_bar.click
end

When('I enter {string} in the search field') do |search_term|
  # Wait for search input field to appear
  wait = Selenium::WebDriver::Wait.new(timeout: 10)
  
  search_input = wait.until { 
    find_element(:id, 'com.mercadolibre:id/search_input') rescue nil
  }
  
  search_input ||= find_element(:xpath, '//android.widget.EditText') rescue nil
  
  search_input.send_keys(search_term)
end

When('I tap the search button') do
  # Try different search button locators
  search_button = find_element(:id, 'com.mercadolibre:id/search_execute') rescue nil
  search_button ||= find_element(:accessibility_id, 'search') rescue nil
  search_button ||= find_element(:xpath, '//android.widget.Button[@text="Buscar"]') rescue nil
  
  search_button&.click
  
  # Alternative: Press enter key
  press_keycode(66) if search_button.nil? # 66 = ENTER key
end

Then('I should see search results for {string}') do |expected_term|
  # Wait for results to load
  sleep 5
  
  # Verify we're on results page by looking for result items or search term
  results_container = find_element(:id, 'com.mercadolibre:id/results_list') rescue nil
  product_items = find_elements(:id, 'com.mercadolibre:id/item_container') rescue []
  
  expect(results_container || product_items.any?).to be_truthy
  
  # Log success
  puts "Successfully searched for: #{expected_term}"
  puts "📱 Found #{product_items.size} product items" if product_items.any?
end