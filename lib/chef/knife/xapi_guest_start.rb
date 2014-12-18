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
require 'chef/knife/xapi_vmselect'

class Chef
  class Knife
    class XapiGuestStart < Knife
      include Chef::Knife::XapiBase

      banner 'knife xapi guest start'

      include Chef::Knife::XapiVmSelect

      def run
        vm = select_vm(@name_args[0])

        if vm.is_a? Array
          vm.each { |vm| start(vm) }
        else
          start(vm)
        end
      end
    end
  end
end
