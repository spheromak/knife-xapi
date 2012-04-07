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

      def run
        vms = xapi.VM.get_all
        printf "%-25s  %-46s  %-36s \n", "Name Label", "Ref", "UUID"
        vms.each do |vm|
          record = xapi.VM.get_record(vm)
          # make  sure you can't do bad things to these VM's
          next if record['is_a_template'] 
          next if record['name_label'] =~ /control domain/i
          printf "%-25s  %46s  %36s \n", record['name_label'], vm, record['uuid']
        end
      end

    end
  end
end
