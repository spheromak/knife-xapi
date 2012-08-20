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
    class XapiVdiDelete < Knife
      include Chef::Knife::XapiBase

      banner "knife xapi vdi delete NAME_LABEL (options)"

      option :uuid,
        :short => "-U",
        :long => "--uuid",
        :description => "Treat the label as a UUID not a name label"

      option :cleanup,
        :short => "-C",
        :long => "--cleanup",
        :description => "Clean up all orphaned volumes."

      option :interactive,
        :short => "-I",
        :long => "--interactive",
        :description => "Interactive clean-up of orphaned volumes"

      def run 
        if config[:interactive]
          # Get all VDIs known to the system
          vdis = get_all_vdis()
          first = true

          for vdi_ in vdis do
            vbds = get_vbds_from_vdi(vdi_)
            if vbds.empty? and xapi.VDI.get_type(vdi_).match('system')
              if first
                first = false
              end

              print_vdi_info(vdi_)
              ret = yes_no_prompt("  No VM attached! Do you want to destroy this volume? (Type \'yes\' or \'no\'): ")

              if ret
                destroy_vdi(vdi_)
              end
            end
          end

        elsif config[:cleanup]
          orphaned_vdis = []
          vdis = get_all_vdis()

          for vdi_ in vdis do
            vbds = get_vbds_from_vdi(vdi_)
            if vbds.empty? and xapi.VDI.get_type(vdi_).match('system')
              orphaned_vdis << vdi_
            end
          end

          for item in orphaned_vdis do
            print_vdi_info(item)
          end

          unless orphaned_vdis.empty?
            ret = yes_no_prompt("Do you want to destroy all these volumes? (Type \'yes\' or \'no\'): ")
            if ret
              for item in orphaned_vdis do
                destroy_vdi(item)
              end
            end
          end

        else
          vdi_name = @name_args[0]
          if vdi_name.nil?
            puts "Error: No VDI Name specified..."
            puts "Usage: " + banner
            exit 1
          end

          vdis = [] 
          if config[:uuid]
            vdis << get_vdi_by_uuid(vdi_name)
          else
            vdis << get_vdi_by_name_label(vdi_name)
          end
          vdis.flatten! 

          if vdis.empty? 
            puts "VDI not found: #{h.color vdi_name, :red}" 
            exit 1
          elsif vdis.length > 1
            puts "Multiple VDI matches found. Use vdi list if you are unsure"
            vdi = user_select(vdis)
          else 
            vdi = vdis.first
          end

          vbds = get_vbds_from_vdi(vdi)

          if vbds.empty? 
            destroy_vdi(vdi)
          else
            puts "ERROR! The VDI is still in use."
          end
        end
      end
    end
  end
end
