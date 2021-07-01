require 'json'
require 'table_print'

class Conjur::Command::Authenticators < Conjur::Command

  desc "Manage authenticators"
  command :authenticator do |authenticator|

    authenticator.desc "List authenticators"
    authenticator.command :list do |c|
      c.action do |global_options,options,args|
        puts "Listing authenticators..."
        resp = JSON.parse(api.authenticator_list.body)

        authenticators = resp['configured'].map do |name|
          {
            name: name,
            enabled: resp['enabled'].include?(name)
          }
        end

        tp authenticators
      end
    end

    authenticator.desc "Enable an authenticator"
    authenticator.arg_name "AUTHENTICATOR"
    authenticator.command :enable do |c|
      c.action do |global_options,options,args|
        id = require_arg(args, "AUTHENTICATOR")

        authenticator_type = id.split('/')[0]
        service_id = id.split('/')[1]

        puts "Enabling #{id}..."
        api.authenticator_enable(authenticator_type, service_id)
      end
    end

    authenticator.desc "Disable an authenticator"
    authenticator.arg_name "AUTHENTICATOR"
    authenticator.command :disable do |c|
      c.action do |global_options,options,args|
        id = require_arg(args, "AUTHENTICATOR")

        authenticator_type = id.split('/')[0]
        service_id = id.split('/')[1]

        puts "Disabling #{id}..."
        api.authenticator_disable(authenticator_type, service_id)
      end
    end

    authenticator.desc "Check the status of an authenticator"
    authenticator.arg_name "AUTHENTICATOR"
    authenticator.command :status do |c|
      c.action do |global_options,options,args|
        id = require_arg(args, "AUTHENTICATOR")

        authenticator_type = id.split('/')[0]
        service_id = id.split('/')[1]

        puts "Getting status for #{id}..."
        resp = api.authenticator_status(authenticator_type, service_id)
        puts resp.body
      end
    end
  end
end
