require 'spec_helper'

describe Conjur::Command::Roles, logged_in: true do
  let(:all_roles) { %w(foo:user:joerandom foo:something:cool foo:something:else foo:group:admins) }
  let(:role) do
    double "the role", all: all_roles.map{|r| double r, roleid: r }
  end

  before do
    api.stub(:role).with(rolename).and_return role
  end

  context "when logged in as a user" do
    let(:username) { "joerandom" }
    let(:rolename) { "user:joerandom" }

    describe_command "role:memberships" do
      it "lists all roles" do
        JSON::parse(expect { invoke }.to write).should == all_roles
      end
    end

    describe_command "role:memberships foo:bar" do
      let(:rolename) { 'foo:bar' }
      it "lists all roles of foo:bar" do
        JSON::parse(expect { invoke }.to write).should == all_roles
      end
    end
  end

  context "when logged in as a host" do
    let(:username) { "host/foobar" }
    let(:rolename) { "host:foobar" }

    describe_command "role:memberships" do
      it "lists all roles" do
        JSON::parse(expect { invoke }.to write).should == all_roles
      end
    end
  end
end
