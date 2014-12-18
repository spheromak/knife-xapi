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
require 'pry'
class Chef
  class Knife
    class XapiNetList < Knife
      include Chef::Knife::XapiBase

      banner 'knife xapi net list'

      def run
        xapi.network.get_all_records.each do |_k, net|
          color_kv 'Name: ',   net['name_label']
          color_kv '  Info: ', net['name_description'], [:magenta, :cyan]  unless net['name_description'].empty?
          color_kv '   MTU: ', net['MTU'], [:magenta, :cyan]
          color_kv '  UUID: ', net['uuid'], [:magenta, :cyan]
          ui.msg ''
        end
      end
    end
  end
end
