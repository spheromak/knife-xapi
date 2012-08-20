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
    class XapiVdiAttach < Knife
      include Chef::Knife::XapiBase

      banner "knife xapi vdi attach VM_name VDI_name (options)"

      option :uuid,
        :short => "-U",
        :long => "--uuid",
        :description => "Treat the label as a UUID not a name label"

      option :boot,
        :long => "--boot",
        :default => false,
        :description => "Set the new disk as bootable (default: false)"
	  
      def run
	      vm_name = @name_args[0]
        vdi_name = @name_args[1]
        
        # There is no matchs with VM and VDI's name label 
		    if vm_name.nil? or vdi_name.nil?
	  	    ui.msg "Error: No VM Name or VDI Name specified..."
	        ui.msg "Usage: " + banner
	  	    exit 1
		    end

        # Get VM's ref from its name label 
        vm_ref = xapi.VM.get_by_name_label(vm_name)
        if vm_ref.empty?
          ui.msg ui.color "Could not find a vm named #{vm_name}", :red
          exit 1
        end
        vm_ref = vm_ref.shift


	      # Get VDI's ref from its name label or UUID
	      vdis = [] 
        if config[:uuid]
          vdis << xapi.VDI.get_by_uuid(vdi_name)
	      else
          vdis = xapi.VDI.get_by_name_label(vdi_name)
        end

	      if vdis.empty?
          ui.msg "VDI not found: #{h.color vdi_name, :red}"
          exit 1  
        # When multiple VDI matches
        Chef::Log.debug "VDI Length: #{vdis.inspect}\nType:#{vdi.class}" 
        elsif vdis.length > 1
	        ui.msg "Multiple VDI matches found use guest list if you are unsure"
		      vdi_ref = user_select(vdis)
	      else
			    vdi_ref = vdis.first
	      end
	     

        position = xapi.VM.get_VBDs(vm_ref).length

        # Attach intended VDI to specific VM
        if vdi_ref == :all
          vdis.each do |vdi_ref|
            create_vbd(vm_ref, vdi_ref, position, config[:boot] )
            position += 1
          end
        else 
          create_vbd(vm_ref, vdi_ref, position, config[:boot])
        end

	    end	
	  end
  end
end



