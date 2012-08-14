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
	    include Chef::Knife::XapiBase

	    banner "knife xapi vdi detach NAME_LABEL (options)"

	    option :uuid,
	      :short => "-U",
	      :long => "--uuid",
		    :description => "Treat the label as a UUID not a name label"
	  
	    def run
	      vbd_name = @name_args[0]

		    if vbd_name.nil?
		      ui.msg "Error: No VDI Name specified..."
		      ui.msg "Usage: " +banner
		      exit 1
		    end
		
        vdis = []  
        # detach vdi with VDI's UUID
	      if config[:uuid]
          vdis << xapi.VDI.get_by_uuid(vbd_name)
        else
        # detach with VDI's Name 
          vdis = xapi.VDI.get_by_name_label(vbd_name)
	      end

        if vdis.empty?
	        ui.msg "VDI not found: #{h.color vbd_name, :red}"
	    	  exit 1
		    # When multiple VDI matches
	      elsif vdis.length > 1
			    ui.msg "Multiple VDI matches found use guest list if you are unsure"
			    vdi_ref = user_select(vdis)
	      else
			    vdi_ref = vdis.first
		    end
			  
        # Detach VDI	
        if vdi_ref == :all
          vdis.each{|vdi_ref| detach_vdi(vdi_ref)}
        else
          detach_vdi(vdi_ref)
        end
        
     end
	  end
  end
end

	  



