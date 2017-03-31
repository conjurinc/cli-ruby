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

class Conjur::Command::Assets < Conjur::Command
  # Toplevel command
  desc "Manage assets"
  command :asset do |asset|
    hide_docs(asset)
    asset.desc "Create an asset"
    asset.arg_name "kind:id"
    asset.command :create do |create|
      hide_docs(create)
      acting_as_option(create)
      create.action do |global_options, options, args|
        # NOTE: no generic functions there, as :id is optional
        kind, id = require_arg(args, 'kind:id').split(':')
        id = nil if id.blank?
        kind.gsub!('-', '_')

        m = "create_#{kind}"
        record = if [ 1, -1 ].member?(api.method(m).arity)
                   if id
                     options[:id] = id
                   end
                   api.send(m, options)
                 else
                   unless id
                     raise "for kind #{kind} id should be specified explicitly after colon"
                   end
                   api.send(m, id, options)
                 end
        display(record, options)
      end
    end

    asset.desc "Show an asset"
    asset.arg_name "id"
    asset.command :show do |c|
      c.action do |global_options,options,args|
        kind, id = get_kind_and_id_from_args(args, 'id')
        display api.send(kind, id).attributes
      end
    end

    asset.desc "Checks for the exisistance of an asset"
    asset.arg_name "id"
    asset.command :exists do |c|
      c.action do |global_options,options,args|
        kind, id = get_kind_and_id_from_args(args, 'id')
        puts api.send(kind, id).exists?
      end
    end

    asset.desc "List assets of a given kind"
    asset.arg_name "kind"
    asset.command :list do |c|
      hide_docs c
      c.action do |global_options,options,args|
        kind = require_arg(args, "kind").gsub('-', '_')
        if api.respond_to?(kind.pluralize)
          api.send(kind.pluralize)
        else
          api.resources(kind: kind)
        end.each do |e|
          display(e, options)
        end
      end
    end

    asset.desc "Manage asset membership"
    asset.command :members do |members|
      members.desc "Add a member to an asset"
      members.arg_name "id role-name member"
      members.command :add do |c|
        hide_docs(c)
        c.desc "Grant with admin option"
        c.flag [:a, :admin]

        c.action do |global_options, options, args|
          kind, id = get_kind_and_id_from_args(args, 'id')
          role_name = require_arg(args, 'role-name')
          member = require_arg(args, 'member')
          admin_option = !options.delete(:admin).nil?

          api.send(kind, id).add_member role_name, member, admin_option: admin_option
          puts "Membership granted"
        end
      end

      members.desc "Remove a member from an asset"
      members.arg_name "id role-name member"
      members.command :remove do |c|
        hide_docs c
        c.action do |global_options, options, args|
          kind, id = get_kind_and_id_from_args(args, 'id')
          role_name = require_arg(args, 'role-name')
          member = require_arg(args, 'member')
          api.send(kind, id).remove_member role_name, member
          puts "Membership revoked"
        end
      end
    end
  end
  
  desc "Provision cloud resources for an asset"
  arg_name "provisioner kind:id"
  command :provision do |c|
    c.action do |global_options, options, args|
      provisioner = require_arg(args, 'provisioner')
      kind, id = get_kind_and_id_from_args args, 'kind:id'
      asset = api.send(kind, id)
      raise "asset #{kind}:#{id} does not exist" unless asset.exists?
      path = "conjur/provisioner/#{kind}/#{provisioner}"
      
      # Hmm could be DRYer
      begin
        require path
      rescue LoadError => ex
        raise "unable to find #{provisioner} provisioner for #{kind} asset (LoadError while requiring #{path})"
      end

      begin 
        name = path.classify
        mod = name.constantize
      rescue NameError
        raise "unable to find #{provisioner} provisioner for #{kind} asset (missing const #{name})"
      end
      
      asset.extend mod
      
      if Conjur.log
        Conjur.log << "provisioning asset #{kind}:#{id} for #{provisioner}"
      end
      asset.provision
    end
  end
end
