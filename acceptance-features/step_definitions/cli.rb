Then /^I show the output$/ do
  puts all_output
end

# this is step copypasted from https://github.com/cucumber/aruba/blob/master/lib/aruba/cucumber.rb#L24 
# original has typo in regexp, which is fixed here
Given(/^a file named "([^"]*?)" with: '(.*?)'$/) do |file_name, file_content|
  file_content.gsub!('$ns',@namespace)
  write_file(file_name, file_content)
end

Given(/^a file named "([^"]*?)" with namespace substitution:$/) do |file_name, file_content|
  step "a file named \"#{file_name}\" with:", file_content.gsub('$ns',@namespace)
end

Then /^it prints the path to temporary file which contains: '(.*)'$/ do |content|
  filename = all_output.split("\n").last
  tempfiles << filename
  actual_content=File.read(filename) rescue ""
  expect(actual_content).to match(content)
end
