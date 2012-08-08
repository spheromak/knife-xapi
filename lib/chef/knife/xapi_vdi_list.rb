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
require 'pp'

class Chef
  class Knife
    class XapiVdiList < Knife
      include Chef::Knife::XapiBase

      banner "knife xapi vdi list"

      def run 
          # Get all VDIs known to the system
          vdis = xapi.VDI.get_all()
	      pp vdis

          puts "================================================"
          for vdi_ in vdis do
            puts "#{h.color "VDI name: " + xapi.VDI.get_name_label(vdi_), :green}"
            puts "  -UUID: " + xapi.VDI.get_uuid(vdi_)
            puts "  -Description: " + xapi.VDI.get_name_description(vdi_)
            puts "  -Type: " + xapi.VDI.get_type(vdi_)

            vbds = xapi.VDI.get_VBDs(vdi_)
            for vbd in vbds do
              vm = xapi.VBD.get_VM(vbd)
              state = xapi.VM.get_power_state(vm)
              puts "    -VM name: " + xapi.VM.get_name_label(vm)
              puts "    -VM state: " + state + "\n"
            end

            if vbds.empty? and xapi.VDI.get_type(vdi_).match('system')
                puts "  No VM attached!"
                #puts "  No VM attached! Use vdi delete --cleanup to delete this volume."
            end
            puts "================================================"
          end
      end
    end
  end
end

