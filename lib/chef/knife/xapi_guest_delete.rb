#
# Author:: Jesse Nelson (<spheromak@gmail.com>)
#
# Copyright:: Copyright (c) 2012 Jesse Nelson
#
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#


require 'chef/knife/xapi_base'

class Chef
  class Knife
    class XapiGuestDelete < Knife
      include Chef::Knife::XapiBase

      deps do
        require 'chef/api_client'
        require 'chef/json_compat'
      end

      banner "knife xapi guest delete NAME_LABEL (options)"

      option :uuid,
          :short => "-U",
          :long => "--uuid",
          :description => "Treat the label as a UUID not a name label"

      option :keep_client,
        :short => "-C",
        :long => "--keep-client",
        :description => "Keep client info on the chef-server"

      option :keep_node,
        :short => "-N",
        :long => "--keep-node",
        :description => "Keep node info on the chef-server"

      def run 
        server_name = @name_args[0]

        if server_name.nil?
          puts "Error: No VM Name specified..."
          puts "Usage: " + banner
          exit 1
        end

        name = server_name
        if config[:uuid]
          name = get_name_label(vm)
        end

        vms = [] 
        if config[:uuid]
          vms << xapi.VM.get_by_uuid(server_name)
        else
          vms << xapi.VM.get_by_name_label(server_name)
        end
        vms.flatten! 

        if vms.empty? 
          puts "VM not found: #{h.color server_name, :red}" 
          exit 1
        elsif vms.length > 1
          puts "Multiple VM matches found use guest list if you are unsure"
          vm = user_select(vms)
        else 
          vm = vms.first
        end
        
        # Cleanup the VM
        cleanup(vm)

        #############################################
        # Delete client and node on the chef server #
        #############################################
        unless config[:keep_client]
          client_list = Chef::ApiClient.list

          if client_list.has_key?(name_label)	
            ui.msg "Removing client  #{h.color name, :cyan} from chef"
            delete_object(Chef::ApiClient, name)
          else
            puts "Client not found on the chef server.. Nothing to delete.."
          end
        end

        unless config[:keep_node]
          env = Chef::Config[:environment]
          node_list = env ? Chef::Node.list_by_environment(env) : Chef::Node.list
          if node_list.hask_key?(name)
            ui.msg "Removing node #{h.color name, :cyan} from chef "
            delete_object(Chef::Node, name)
          else
            puts "Node not found on the chef server.. Nothing to delete.."
          end
        end
      end

    end
  end
end
