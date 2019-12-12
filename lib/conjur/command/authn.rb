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


class Conjur::Command::Authn < Conjur::Command
  desc "Login and logout"
  command :authn do |authn|
    authn.desc "Logs in and caches credentials to netrc."
    authn.arg_name "login-name"
    authn.long_desc <<-DESC
Logins in a user. Login name can be provided as the command argument, as -u or --username, or the command will prompt
for the username. Password can be provided as -p, --password, or the command will prompt for the password.

On successful login, the password is exchanged for the API key, which is cached in the operating system user's
.netrc file. Subsequent "conjur" commands will authenticate with the cached login name and API key. To switch users, 
login again using the new user credentials. To erase credentials, use the 'authn logout' command.
    DESC
    authn.command :login do |c|
      c.arg_name 'username'
      c.flag [:u,:username]

      c.arg_name 'password'
      c.flag [:p,:password]

      c.action do |global_options,options,args|
        if options[:username].blank? && !args.empty?
          options[:username] = args.pop
        end
        
        Conjur::Authn.login(options.slice(:username, :password))
        
        puts "Logged in"
      end
    end

    authn.desc "Obtains an authentication token using the current logged-in user"
    authn.command :authenticate do |c|
      c.desc "Base64 encode the result and format as an HTTP Authorization header"
      c.switch [:H,:header]

      c.arg_name 'filename'
      c.desc 'Keeps a fresh access token in the indicated file. With this argument, the command runs forever.'
      c.flag [ :f, :filename ]

      c.action do |global_options,options,args|
        # Authenticate will try and parse the token file to read the expiration time.
        # It only knows how to do that if the token file contains a JSON access token.
        raise "--header option is not supported with --filename option" if options[:header] && options[:filename]

        authenticate = lambda { 
          Conjur::Authn.authenticate
        }
    
        if filename = options[:filename]
          Conjur::Authenticator.run authenticate: authenticate, filename: filename
        else
          formatter = if options[:header]
            lambda {|token| "Authorization: Token token=\"#{Base64.strict_encode64(JSON.generate token)}\"" }
          else
            lambda {|token| JSON.pretty_generate token }
          end

          puts formatter.call(authenticate.call)
        end
      end
    end

    authn.desc "Logs out"
    authn.command :logout do |c|
      c.action do
        Conjur::Authn.delete_credentials

        puts "Logged out"
      end
    end

    authn.desc "Prints out the current logged in username"
    authn.command :whoami do |c|
      c.action do
        begin
          creds = Conjur::Authn.get_credentials(noask: true)
          puts({account: Conjur.configuration.account, username: creds[0]}.to_json)
        rescue Conjur::Authn::NoCredentialsError
          exit_now! 'Not logged in.', -1
        end
      end
    end

    authn.desc "Prints out the current Conjur certificate authority (CA) certificate chain"
    authn.command :ca do |c|
      c.action do
        if Conjur.configuration.ssl_certificate
          puts Conjur.configuration.ssl_certificate
        elsif Conjur.configuration.cert_file
          puts IO.read(Conjur.configuration.cert_file)
        else
          exit_now! 'No certificate configured.', -1
        end
      end
    end
  end
end
