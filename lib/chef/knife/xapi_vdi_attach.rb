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
      require 'timeout'
      include Chef::Knife::XapiBase

      banner "knife xapi vdi attach VM_name VDI_name (options)"

      option :uuid,
      :short => "-U",
      :long => "--uuid",
      :description => "Treat the label as a UUID not a name label"
	  
	  def run
	    vm_name = @name_args[0]
		vdi_name = @name_args[1]
        # There is no matchs with VM and VDI's name label 
		if vm_name.nil?||vdi_name.nil?
		  puts "Error: No VM Name or VDI Name specified..."
	      puts "Usage: " + banner
		  exit 1
		end

        # Get VM's ref from its name label 
		vm_ref = xapi.VM.get_by_name_label(vm_name)
  
	    # Get VDI's ref from its name label or UUID
	    if config[:uuid]
          vdi_ref = xapi.VDI.get_by_uuid(vdi_name)
	      vdi = vdi_ref
	    else
          vdi_ref = xapi.VDI.get_by_name_label(vdi_name)
          # When multiple VDI matches
	      if vdi_ref.length > 1
	        puts "Multiple VDI matches found use guest list if you are unsure"
		    vdi = user_select_detach(vdi_ref)
	      else
			vdi = vdi_ref.first
	      end
	    end
		vm = vm_ref.first
        
        # Attach intended VDI to specific VM  
      	check = xapi.VDI.get_VBDs(vdi)
	    position = xapi.VM.get_VBDs(vm).length
        
        # VDI is available -> R/W
	    if check.empty? and xapi.VDI.get_type(vdi).match('system') 
          vbd_ref = create_vbd_attach(vm, vdi, position, mo="RW")
        # When VDI is attached to another VM -> Read only 
		else
          puts "The VDI is available for Read only" 
		  vbd_ref = create_vbd_attach(vm, vdi, position, mo="RO")
        end
	  end	
	end
  end
end



