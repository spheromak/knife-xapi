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
    class XapiVdiList < Knife
      include Chef::Knife::XapiBase

      banner "knife xapi vdi list"

      def run 
          # Get all VDIs known to the system
          host_name = @name_args[0]

          # if we were passed a guest name find its vdi's 
          # otherwise do it for everything
          vdis = Array.new
          if host_name.nil? or host_name.empty?
            vdis = xapi.VDI.get_all
          else 
            ref = xapi.VM.get_by_name_label( host_name ) 
            vm = xapi.VM.get_record( ref.first )
            vm["VBDs"].each do |vbd|
              vdis << xapi.VBD.get_record( vbd )["VDI"]
            end
          end

          vdis.each do |vdi| 
            print_vdi_info vdi
          end
      end
    end
  end
end

