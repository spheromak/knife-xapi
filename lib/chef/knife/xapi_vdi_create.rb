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
    class XapiVdiCreate < Knife
      require 'timeout'
      include Chef::Knife::XapiBase

      banner "knife xapi vdi create NAME (options)"

      option :xapi_sr,
        :short => "-S Storage repo to provision VM from",
        :long  => "--xapi-sr",
        :proc => Proc.new { |key| Chef::Config[:knife][:xapi_sr] = key },
        :description => "The Xen SR to use, If blank will use pool/hypervisor default"

      option :xapi_disk_size,
        :short => "-D Size of disk. 1g 512m etc",
        :long  =>  "--xapi-disk-size",
        :description => "The size of the root disk, use 'm' 'g' 't' if no unit specified assumes g",
        :proc => Proc.new { |key| Chef::Config[:knife][:xapi_disk_size] = key.to_s }

      def run
        disk_name = @name_args[0]
        if disk_name.nil?
          puts "Error: No Disk Name specified..."
          puts "Usage: " + banner
          exit 1
        end

        begin
          if locate_config_value(:xapi_sr)
            sr_ref = get_sr_by_name( locate_config_value(:xapi_sr) )
          else
            sr_ref = find_default_sr
          end

          if sr_ref.nil?
            ui.error "SR specified not found or can't be used Aborting"
          end
          Chef::Log.debug "SR: #{h.color sr_ref, :cyan}"

	    	  size = locate_config_value(:xapi_disk_size) 

          vdi_record = {
            "name_label" => disk_name,
            "name_description" => "#{disk_name} created by #{ENV['USER']}",
            "SR" => sr_ref,
            "virtual_size" => input_to_bytes(size).to_s,
            "type" => "system",
            "sharable" => false,
            "read_only" => false,
            "other_config" => {},
          }

          # Async create the VDI
          task = xapi.Async.VDI.create(vdi_record)
          ui.msg "waiting for VDI Create.."
          vdi_ref = get_task_ref(task)

          ui.msg "Disk Name:   #{ h.color( disk_name, :bold, :cyan)}"
          ui.msg "Disk Size:   #{ h.color( size.to_s, :bold, :cyan)}"

        end
      end
    end
  end
end

