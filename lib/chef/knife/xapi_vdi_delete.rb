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


      def interactive
        # Get all VDIs known to the system
        vdis = get_all_vdis()
        first = true

        for vdi_ in vdis do
          vbds = get_vbds_from_vdi(vdi_)
          if vbds.empty? and xapi.VDI.get_type(vdi_).match('system')
            if first
              first = false
            end

            prinlt_vdi_info(vdi_)
            destroy_vdi(vdi_) if yes_no?("Destroy this volume? ")
          end
        end
      end

      def vdi_cleanup
        orphaned_vdis = []
        vdis = get_all_vdis()

        for vdi_ in vdis do
          vbds = get_vbds_from_vdi(vdi_)
          if vbds.empty? and xapi.VDI.get_type(vdi_).match('system')
            orphaned_vdis << vdi_
          end
        end

        orphaned_vdis.each { |item| print_vdi_info(item) }
        unless orphaned_vdis.empty?
          if yes_no?("Destroy all these volumes? ")
            orphaned_vdis.each { |item| destroy_vdi(item) }
          end
        end
      end

      def run 
        if config[:interactive]
          interactive
          return
        elsif config[:cleanup]
          vdi_cleanup
          return
        end

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
          ui.msg "VDI not found: #{h.color vdi_name, :red}" 
          exit 1
        elsif vdis.length > 1
          ui.msg "Multiple VDI matches found. Use vdi list if you are unsure"
          vdi = user_select(vdis)
        else 
          vdi = vdis.first
        end

        if vdi == :all 
          vdis.each {|vdi|  destroy_vdi(vdi)}
        else 
          destroy_vdi(vdi)
        end

      end
    end
  end
end
