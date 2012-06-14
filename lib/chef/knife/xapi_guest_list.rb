#
# Author:: Jesse Nelson <spheromak@gmail.com> 
# Author:: Seung-jin/Sam Kim (<seungjin.kim@me.comm>)
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
    class XapiGuestList < Knife
      include Chef::Knife::XapiBase

      banner "knife xapi guest list"

       option :id,
         :short => "-i",
         :long => "--show-id",
         :description => "Enable printing of UUID and OpaqueRefs for vm"


      def run
        vms = xapi.VM.get_all
        if locate_config_value(:id)
           printf "%-25s  %-12s %-16s %-46s  %-36s \n", "Name Label", "State",  "IP Address", "Ref", "UUID"
        else 
           printf "%-25s  %-12s %-16s\n", "Name Label", "State", "IP Address"
        end

        vms.each do |vm|
          record = xapi.VM.get_record(vm)
          ip_address = get_guest_ip(vm)
          # make  sure you can't do bad things to these VM's
          next if record['is_a_template'] 
          next if record['name_label'] =~ /control domain/i
          if locate_config_value(:id)
            printf "%-25s  %-12s %-16s %46s  %36s \n", record['name_label'], record['power_state'], ip_address, vm, record['uuid']
          else 
            printf "%-25s  %-12s %-16s\n", record['name_label'], record['power_state'], ip_address
          end
        end
      end

    end
  end
end
