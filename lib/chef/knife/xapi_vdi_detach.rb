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
	class XapiVdiDetach < Knife
	  require 'timeout'
	  include Chef::Knife::XapiBase

	  banner "knife xapi vdi detach NAME_LABEL (options)"

	  option :uuid,
	    :short => "-U",
	    :long => "--uuid",
		:description => "Treat the label as a UUID not a name label"
	  
	  def run
	    vbd_name = @name_args[0]

		if vbd_name.nil?
		  puts "Error: No VDI Name specified..."
		  puts "Usage: " +banner
		  exit 1
		end
		
        vbds = []
        
        # detach vdi with VDI's UUID
	    if config[:uuid]
          #vbds << get_vbd_by_uuid(vbd_name)
		  vdi_ref = xapi.VDI.get_by_uuid(vbd_name)
		  vbds << xapi.VDI.get_VBDs(vdi_ref)
	
        # detach with VDI's Name 
	    else
          vdi_ref = get_vdi_by_name_label(vbd_name)
	      
	      if vdi_ref.empty?
	        puts "VDI not found: #{h.color vbd_name, :red}"
			exit 1
		  # When multiple VDI matches
	      elsif vdi_ref.length > 1
			puts "Multiple VDI matches found use guest list if you are unsure"
			vdi_temp = user_select_detach(vdi_ref)
	      else
			vdi_temp = vdi_ref.first
		  end
							          
          vbds <<  xapi.VDI.get_VBDs(vdi_temp)
		    
	    end
        vbds.flatten!
		vbd = vbds.first
        
        # Detach the VDI #
        detach_vdi(vbd)
		  
	  end
	end
  end
end

	  



