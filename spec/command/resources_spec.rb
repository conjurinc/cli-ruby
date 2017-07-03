require 'spec_helper'

describe Conjur::Command::Resources, logged_in: true do

  let (:full_resource_id) { [account, KIND, ID].join(":") }
  let (:resource_instance) { double('resource_instance', attributes: resource_attributes) }
  let (:resource_attributes) { { "some" => "attribute"} }

  before :each do
    allow(api).to receive(:resource).with(full_resource_id).and_return(resource_instance)
  end 

  def invoke_silently
    expect { invoke }.to write
  end

  shared_examples 'it displays resource attributes' do
    it "as JSON to stdout" do
      expect(JSON::parse( expect { invoke }.to write )).to eq(resource_attributes)
    end
  end

  shared_examples "it obtains resource by id" do
    it 'id is built from kind and id' do
      expect(api).to receive(:resource).with(%r{^[^:]*:#{KIND}:#{ID}$})
      invoke_silently
    end
    it 'uses default account as a prefix' do
      expect(api).to receive(:resource).with(%r{^#{account}:})
      invoke_silently
    end
  end

  describe_command "show #{KIND}:#{ID}" do
    it_behaves_like "it obtains resource by id"
    it_behaves_like "it displays resource attributes"
  end

  describe_command "resource:exists #{KIND}:#{ID}" do
    before (:each) { 
      allow(resource_instance).to receive(:exists?).and_return("true")
    }
    it_behaves_like "it obtains resource by id" 
    it 'calls resource.exists?' do
      expect(resource_instance).to receive(:exists?)
      invoke_silently
    end
    context 'displays response of resource.exists? (true/false)' do
      # NOTE: a bit redundant, but will be helpful in 'documentation' context
      it 'true' do
        allow(resource_instance).to receive(:exists?).and_return("true")
        expect { invoke }.to write "true"
      end
      it 'false' do
        allow(resource_instance).to receive(:exists?).and_return("false")
        expect { invoke }.to write "false"
      end
    end
  end

  describe_command "check #{KIND}:#{ID} #{PRIVILEGE}" do
    it "performs a permission check for the logged-in user" do
      expect(resource_instance).to receive(:permitted?).with(PRIVILEGE, role: nil)
      
      invoke
    end
  end

  describe_command "check -r #{ROLE} #{KIND}:#{ID} #{PRIVILEGE}" do
    it "performs a permission check for #{ROLE}" do

      expect(resource_instance).to receive(:permitted?).with(PRIVILEGE, role: ROLE)
      invoke_silently
    end
  end

  describe_command "resource:permitted_roles #{KIND}:#{ID} #{PRIVILEGE}" do
    let(:roles_list) { %W[klaatu barada nikto] }
    before(:each) { 
      allow(resource_instance).to receive(:permitted_roles).and_return(roles_list) 
    }
    it_behaves_like "it obtains resource by id"
    it "calls resource.permitted_roles(#{PRIVILEGE}" do
      expect(resource_instance).to receive(:permitted_roles)
      invoke_silently
    end
    it "displays JSONised list of roles" do
      expect(JSON.parse( expect { invoke }.to write )).to eq(roles_list)
    end
  end
end
