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

      banner "knife xapi guest delete NAME_LABEL (options)"

      option :uuid,
          :short => "-U",
          :long => "--uuid",
          :description => "Treat the label as a UUID not a name label"

      def run 
        server_name = @name_args[0]

        vms = [] 
        if config[:uuid]
          vms << xapi.VM.get_by_uuid(server_name)
        else
          vms << xapi.VM.get_by_name_label(server_name)
        end
        vms.flatten! 

        if vms.empty? 
          ui.msg "VM not found: #{h.color server_name, :red}" 
          exit 1
        elsif vms.length > 1
          ui.msg "Multiple VM matches found use guest list if you are unsure"
          vm = user_select(vms)
        else 
          vm = vms.first
        end

        # shutdown and dest
        unless xapi.VM.get_power_state(vm) == "Halted" 
          print "Shutting down Guest:" 
          task = xapi.Async.VM.hard_shutdown(vm)
          wait_on_task(task)
          print " #{h.color "Done", :green} \n"
        end

        print "Destroying Guest: #{h.color( server_name, :cyan)} " 
        task = xapi.Async.VM.destroy(vm) 
        wait_on_task(task)
        print " #{h.color "Done", :green}\n"
      end

    end
  end
end

