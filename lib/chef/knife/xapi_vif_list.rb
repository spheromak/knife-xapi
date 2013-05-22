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
    class XapiVifList < Knife
      include Chef::Knife::XapiBase

      banner "knife xapi vif list"

      option :vif_name,
        :short => "-N",
        :long => "--vif-name",
        :default => false,
        :description => "Indicates this is a vif name not a guest name"

      def run 
        # Get all vifs known to the system
        name = @name_args[0]

        # if we were passed a guest name find its vdi's 
        # otherwise do it for everything
        vifs = Array.new
        if name.nil? or name.empty?
          vifs = xapi.VIF.get_all

        elsif config[:vif_name]
          vdis = xapi.VIF.get_by_name_label( name )

        else
          ref = xapi.VM.get_by_name_label( name ) 
          vm = xapi.VM.get_record( ref.first )

          vm["VIFs"].each do |vif|
            vdis << xapi.VIF.get_record( vif )["VIF"]
          end
        end

        vifs.each do |vif| 
          print_vif_info vif
        end

      end
    end
  end
end

