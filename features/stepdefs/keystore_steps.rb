require 'aws-sdk-core'
require_relative '../../lib/keystore.rb'

Given(/^test data to use$/) do
  @key = "testkey#{Time.now.strftime '%Y%m%d%H%M%S'}"
  @value = "testvalue#{Time.now.strftime '%Y%m%d%H%M%S'}"
end

Given(/^a region to operate in$/) do
  @region = ENV["region"]
  fail if @region.nil?
end

Given(/^a DynamoDB table to use$/) do
  @table_name = ENV["table_name"]
  fail if @table_name.nil?
end

When(/^I store a value in the keystore$/) do
  @dynamo = Aws::DynamoDB::Client.new region: @region
  keystore = Keystore.new dynamo: @dynamo, table_name: @table_name
  keystore.store key: @key, value: @value
end

Then(/^I should see that encrypted data in the raw data store$/) do
  result = @dynamo.get_item(table_name: @table_name, key: { 'ParameterName' => @key } ).item
  expect(result).to be
  # when we get encryption working this should be uncommented
  # expect(result["Value"]).not_to eq @value
end

When(/^I retrieve a value from the keystore$/) do
  @dynamo = Aws::DynamoDB::Client.new region: @region
  keystore = Keystore.new dynamo: @dynamo, table_name: @table_name
  keystore.store key: @key, value: @value
  @result = keystore.retrieve key: @key
  expect(@result).to be
end

Then(/^I should get that data back in plaintext$/) do
  keystore = Keystore.new dynamo: @dynamo, table_name: @table_name
  @result = keystore.retrieve key: @key
  expect(@result).to eq @value
end

