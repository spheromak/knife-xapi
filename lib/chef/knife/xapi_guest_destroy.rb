#
# Author:: Seung-jin/Sam Kim (<seungjin.kim@me.comm>)
#
#  Based on xapi plugin written by 
# Author:: Adam Jacob (<adam@opscode.com>)
#
# Copyright:: Copyright (c) 2012 Seung-jin Kim
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

      banner "knife xapi guest destory [NETWORKS] (options)"

      #option :destroy_target_vm,
      #  :short => "-D BOOTSTRAP",
      #  :long => "--xapi-bootstrap BOOTSTRAP",
      #  :description => "bootstrap template to push to the server",
      #  :proc => Proc.new { |bootstrap| Chef::Config[:knife][:xapi_bootstrap] = bootstrap }
      
      def run
        vms = xapi.VM.get_all
      end
      end

    end
  end
end