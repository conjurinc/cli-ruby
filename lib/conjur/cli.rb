#
# Copyright (C) 2013 Conjur Inc
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
require 'gli'
require 'conjur/config'
require 'conjur/log'
require 'conjur/identifier_manipulation'

module Conjur
  class CLI
    extend GLI::App

    class << self
      def load_config
        Conjur::Config.load
      end
      
      def apply_config
        Conjur::Config.apply
      end

      # Automatically load any plugins that might be installed.
      # You can still add a plugin to the rc file to have conjur complain if missing.
      def autoload_plugins
        files = Gem.find_files('/conjur-asset-*.rb').reject { |p| p =~ /-version.rb$/ }
        files.each do |f|
          require f
        end
      end
    end
          
    load_config
    autoload_plugins

    Conjur::Config.plugins.each do |plugin|
      begin
        filename = "conjur-asset-#{plugin}"
        require filename
      rescue LoadError
        warn "Could not load plugin '#{plugin}' specified in your config file.\nMake sure you have the #{filename}-api gem installed."
      end
    end

    commands_from 'conjur/command'

    pre do |global,command,options,args|

      if command.name_for_help.first == "init" and options.has_key?("account") 
        ENV["CONJUR_ACCOUNT"]=options["account"]
      end
      apply_config

      require 'active_support/core_ext'
      options.delete_if{|k,v| v.blank?}
      options.symbolize_keys!
      
      if as_group = options.delete(:"as-group")
        group = Conjur::Command.api.group(as_group)
        role = Conjur::Command.api.role(group.roleid)
        exit_now!("Group '#{as_group}' doesn't exist, or you don't have permission to use it") unless role.exists?
        options[:"ownerid"] = group.roleid
      end
      if as_role = options.delete(:"as-role")
        role = Conjur::Command.api.role(as_role)
        exit_now!("Role '#{as_role}' does not exist, or you don't have permission to use it") unless role.exists?
        options[:"ownerid"] = role.roleid
      end
      
      true
    end
    
    on_error do |exception|
      if exception.is_a?(RestClient::Exception)
        begin
          body = JSON.parse(exception.response.body)
          $stderr.puts body['error']
        rescue
          $stderr.puts exception.response.body if exception.response
        end
      end
      
      if Conjur.log
        Conjur.log << "error: #{exception}\n#{exception.backtrace.join("\n") rescue 'NO BACKTRACE?'}"
      end
      true
    end
  end
end
