require_relative '../lib/keystore.rb'

# mock dynamo return value
class DDBResult
  attr_accessor :item
  def initialize(value)
    @item = { 'Value' => value }
  end
end

# mock KMS return value
class KMSResult
  attr_accessor :ciphertext_blob, :plaintext
  def initialize(value)
    @ciphertext_blob = value
    @plaintext = value
  end
end

RSpec.describe 'Keystore' do
  context 'it can store encrypted values' do
    it 'will call DynamoDB to store the value' do
      mock_ddb = double('AWS::DynamoDB::Client')
      expect(mock_ddb).to receive(:put_item)

      mock_kms = double('AWS::KMS::Client')
      expect(mock_kms).to receive(:encrypt).and_return(KMSResult.new('dontcare'))

      keystore = Keystore.new dynamo: mock_ddb, table_name: 'dontcare', kms: mock_kms, key_id: 'dontcare'

      begin
        keystore.store key: 'testkey', value: 'testvalue'
      rescue StandardError => e
        message = "Unexpected exception thrown: #{e}"
        raise message
      end
    end
  end

  context 'it can retrieve stored values' do
    it 'will return data for a given key' do
      mock_ddb = double('AWS::DynamoDB::Client')
      expect(mock_ddb).to receive(:get_item).and_return(DDBResult.new(Base64.encode64('dontcare')))

      mock_kms = double('AWS::KMS::Client')
      expect(mock_kms).to receive(:decrypt).and_return(KMSResult.new('testvalue'))

      keystore = Keystore.new dynamo: mock_ddb, table_name: 'dontcare', kms: mock_kms

      begin
        result = keystore.retrieve key: 'testkey'
        expect(result).to be
        expect(result).to eq 'testvalue'
      rescue StandardError => e
        message = "Unexpected exception thrown: #{e}"
        raise message
      end
    end
  end
end
