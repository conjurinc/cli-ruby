require 'spec_helper'

describe Conjur::Command::Users, logged_in: true do
  context "updating password" do
    before do
     expect(RestClient::Request).to receive(:execute).with({
        method: :put,
        url: update_password_url,
        user: username, 
        password: api_key,
        headers: { },
        payload: "new-password"
       })
    end
    
    describe_command "user:update_password -p new-password" do
      it "PUTs the new password" do
        invoke
      end
    end
  
    describe_command "user:update_password" do
      it "PUTs the new password" do
        expect(Conjur::Command::Users).to receive(:prompt_for_password).and_return "new-password"

        invoke
      end
    end
  end

  context 'rotating api key' do
    describe_command 'user rotate_api_key' do
      before do
        expect(RestClient::Request).to receive(:execute).with({
                    method: :put,
                    url: 'https://authn.example.com/users/api_key',
                    user: username,
                    password: api_key,
                    headers: {},
                    payload: ''
                }).and_return double(:response, body: 'new api key')
        expect(Conjur::Authn).to receive(:save_credentials).with({
                    username: username,
                    password: 'new api key'
                })
      end

      it 'puts with basic auth' do
        invoke
      end
    end
  end
end
