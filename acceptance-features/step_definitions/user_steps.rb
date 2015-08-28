Given(/^I login as a new user$/) do
  @username_index ||= 0
  username = %w(alice bob charles dave edward)[@username_index]
  raise "I'm out of usernames!" unless username
  @username_index += 1
  @username = "#{username}@$ns"
  step %Q(I login as new user "#{@username}")
end

Given(/^I create a new user named "(.*?)"$/) do |username|
  username_ns = username.gsub('$ns',@namespace)
  password = find_or_create_password(username_ns)
 
  step "I run `conjur user create --as-role user:admin@#{@namespace} -p #{username_ns}` interactively"
  step %Q(I type "#{password}")
  step %Q(I type "#{password}")
  step "the exit status should be 0"
end

Given(/^I create a new host with id "(.*?)"$/) do |hostid|
  step "I successfully run `conjur host create #{@namespace}/monitoring/server`"
  step 'I keep the JSON response at "api_key" as "API_KEY"'
  step 'I keep the JSON response at "id" as "HOST_ID"'
end

Given(/^I login as a new host/) do
  step "I run `conjur authn login -u host/%{HOST_ID} -p %{API_KEY}` interactively"
  step "the exit status should be 0"
end

Given(/^I login as new user "(.*?)"$/) do |username|
  username_ns = username.gsub('$ns',@namespace)
  step %Q(I create a new user named "#{username_ns}")
  step %Q(I login as "#{username_ns}")
end

Given(/^I login as "(.*?)"$/) do |username|
  username_ns = username.gsub('$ns',@namespace)
  password = find_or_create_password(username_ns)
  
  Conjur::Authn.save_credentials username: username_ns, password: password
end

Then(/^I(?: can)? type and confirm a new password/) do
  @password = SecureRandom.hex(12)
  step %Q(I type "#{@password}")
  step %Q(I type "#{@password}")
  step "the exit status should be 0"
end

When(/^I enter the password/) do
  raise "No current password" unless @password
  step %Q(I type "#{@password}")
end
