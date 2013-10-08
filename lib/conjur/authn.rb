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
require 'highline'
require 'conjur/api'
require 'netrc'

module Conjur::Authn
  class << self
    def login(options = {})
      delete_credentials
      get_credentials(options)
    end
    
    def authenticate(options = {})
      Conjur::API.authenticate(*get_credentials(options))
    end
    
    def delete_credentials
      netrc.delete host
      netrc.save
    end
    
    def host
      Conjur::Authn::API.host
    end
    
    def netrc
      @netrc ||= Netrc.read
    end
    
    def get_credentials(options = {})
      @credentials ||= (read_credentials || fetch_credentials(options))
    end
    
    def read_credentials
      netrc[host]
    end
    
    def fetch_credentials(options = {})
      ask_for_credentials(options)
      write_credentials
    end
    
    def write_credentials
      netrc[host] = @credentials
      netrc.save
      @credentials
    end
    
    def ask_for_credentials(options = {})
      raise "No credentials provided or found" if options[:noask]

      # also use stderr here, because we might be prompting for a password as part
      # of a command like user:create that we'd want to send to a file.
      hl = HighLine.new $stdin, $stderr

      user = options[:username] || hl.ask("Enter your username to log into Conjur: ")
      pass = options[:password] || hl.ask("Please enter your password (it will not be echoed): "){ |q| q.echo = false }
      api_key = if cas_server = options[:"cas-server"]
        Conjur::API.login_cas(user, pass, cas_server)
      else
        Conjur::API.login(user, pass)
      end
      @credentials = [user, api_key]
    end
    
    def connect(cls = Conjur::API, options = {})
      cls.new_from_key(*get_credentials(options))
    end
  end
end