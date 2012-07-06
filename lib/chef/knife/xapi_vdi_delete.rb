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
          vdis = xapi.VDI.get_all()
		  first = true

          for vdi_ in vdis do
            vbds = xapi.VDI.get_VBDs(vdi_)
			if vbds.empty? and xapi.VDI.get_type(vdi_).match('system')
				if first
          			puts "================================================"
					first = false
				end

				puts "#{h.color "VDI name: " + xapi.VDI.get_name_label(vdi_), :green}"
				puts "  -Description: " + xapi.VDI.get_name_description(vdi_)
				puts "  -Type: " + xapi.VDI.get_type(vdi_)

				print "  No VM attached! Do you want to destroy this volume? (Type \'yes\' or \'no\'): "
				choice = STDIN.gets

				while !(choice.match(/^yes$|^no$/))
					puts "Invalid input! Type \'yes\' or \'no\':"
					choice = STDIN.gets
				end

				if choice.match('yes')
					  # Destroy VDI object (volume)
					  task = xapi.Async.VDI.destroy(vdi_)
					  puts "Destroying volume.."
					  task_ref = get_task_ref(task)
					  #print "#{h.color "OK.", :green} \n"
				end
				puts "================================================"
			end
          end
		elsif config[:cleanup]
		  orphaned_vdis = []
          vdis = xapi.VDI.get_all()

          for vdi_ in vdis do
            vbds = xapi.VDI.get_VBDs(vdi_)
			if vbds.empty? and xapi.VDI.get_type(vdi_).match('system')
				orphaned_vdis << vdi_
			end
		  end

          for item in orphaned_vdis do
            puts "#{h.color "VDI name: " + xapi.VDI.get_name_label(item), :green}"
            puts "  -Description: " + xapi.VDI.get_name_description(item)
            puts "  -Type: " + xapi.VDI.get_type(item)
		  end

		  #if orphaned_vdis.length > 0
		  unless orphaned_vdis.empty?
				  print "Do you want to destroy all these volumes? (Type \'yes\' or \'no\'): "
				  choice = STDIN.gets
				  while !(choice.match(/^yes$|^no$/))
					puts "Invalid input! Type \'yes\' or \'no\':"
					choice = STDIN.gets
				  end

				  if choice.match('yes')
						for item in orphaned_vdis do
							task = xapi.Async.VDI.destroy(item)
							print "Destroying volume "
							puts "#{h.color xapi.VDI.get_name_label(item), :blue}"
							task_ref = get_task_ref(task)
							#print "#{h.color "OK.", :green} \n"
						end
				  end
		  end
		else
        	vdi_name = @name_args[0]
			vdis = [] 
			if config[:uuid]
			  vdis << xapi.VDI.get_by_uuid(vdi_name)
			else
			  vdis << xapi.VDI.get_by_name_label(vdi_name)
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

			vbds = xapi.VDI.get_VBDs(vdi)

			if vbds.empty? 
				task = xapi.Async.VDI.destroy(vdi)
				print "Destroying volume: "
				task_ref = get_task_ref(task)
			else
				puts "ERROR! The VDI is still in use."
			end
		end
      end
    end
  end
end

