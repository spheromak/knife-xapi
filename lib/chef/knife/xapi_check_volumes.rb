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
    class XapiCheckVolumes < Knife
      include Chef::Knife::XapiBase

      banner "knife xapi check_volumes"

      #option :uuid,
      #    :short => "-U",
      #    :long => "--uuid",
      #    :description => "Treat the label as a UUID not a name label"

      def run 
          # Get all VDIs known to the system
          vdis = xapi.VDI.get_all()
          index = 1

          puts "================================================"
          for vdi_ in vdis do
            puts "#{h.color "VDI name: " + xapi.VDI.get_name_label(vdi_), :green}"
            puts "  -Description: " + xapi.VDI.get_name_description(vdi_)
            puts "  -Type: " + xapi.VDI.get_type(vdi_)

            vbds = xapi.VDI.get_VBDs(vdi_)
            for vbd in vbds do
              #puts "VBD ID: " + xapi.VBD.get_uuid(vbd)
              
              vm = xapi.VBD.get_VM(vbd)
              state = xapi.VM.get_power_state(vm)
              puts "    -VM name: " + xapi.VM.get_name_label(vm)
              puts "    -VM state: " + state + "\n"
            end

            if vbds.empty?
                print "  No VM attached! Do you want to destroy this volume? (Type \'yes\' or \'no\'): "
				choice = STDIN.gets		
				while !(choice.match(/^yes$|^no$/))
        			puts "Invalid input! Type \'yes\' or \'no\':"
					choice = STDIN.gets		
				end

				if choice.match('yes')
					  # Destroy VDI object (volume)
					  task = xapi.Async.VDI.destroy(vdi_)
					  puts "Destroying volume.."
					  task_ref = get_task_ref(task)
					  print "#{h.color "OK.", :green} \n"
				end
            end
            puts "================================================"
          end
      end
    end
  end
end

