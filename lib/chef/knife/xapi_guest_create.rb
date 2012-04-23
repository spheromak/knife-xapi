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
    class XapiGuestCreate < Knife
      include Chef::Knife::XapiBase

      banner "knife xapi guest create NAME [NETWORKS] (options)"

      option :bootstrap,
        :short => "-B BOOTSTRAP",
        :long => "--xapi-bootstrap BOOTSTRAP",
        :description => "bootstrap template to push to the server",
        :proc => Proc.new { |bootstrap| Chef::Config[:knife][:xapi_bootstrap] = bootstrap }

      option :vm_template,
        :short => "-T Template Name Label",
        :long => "--xapi-vm-template",
        :description => "xapi template name to create from. accepts an string or regex",
        :proc => Proc.new { |template| Chef::Config[:knife][:xapi_vm_template] = template }

      option :install_repo,
        :short => "-R If you're using a builtin template you will need to specify a repo url",
        :long => "--xapi-install-repo",
        :description => "Install repo for this template (if needed)",
        :proc => Proc.new { |repo| Chef::Config[:knife][:xapi_install_repo] = repo }

      option :storage_repo,
        :short => "-S Storage repo to provision VM from",
        :long  => "--xapi-sr",
        :description => "The Xen SR to use, If blank will use pool/hypervisor default",
        :proc => Proc.new { |sr| Chef::Config[:knife][:xapi_sr] = sr }

      option :kernel_params,
        :short => "-B Set of kernel boot params to pass to the vm",
        :long => "--xapi-kernel-params",
        :description => "You can add more boot options to the vm e.g.: \"ks='http://foo.local/ks'\"",
        :proc => Proc.new {|kernel| Chef::Config[:knife][:xapi_kernel_params] = kernel }

      option :disk_size,
        :short => "-D Size of disk. 1g 512m etc",
        :long  =>  "--xapi-disk-size",
        :description => "The size of the root disk, use 'm' 'g' 't' if no unit specified assumes g",
        :proc => Proc.new {|disk| Chef::Config[:knife][:xapi_disk_size] = disk } 

      option :cpus,
        :short => "-C Number of VCPUs to provision",
        :long =>  "--xapi-cpus",
        :description => "Number of VCPUS this vm should have 1 4 8 etc",
        :proc => Proc.new {|cpu| Chef::Config[:knife][:xapi_cpus] = cpu }

      option :mem,
        :short => "-M Ammount of memory to provision",
        :long => "--xapi-mem",
        :description => "Ammount of memory the VM should have specify with m g etc 512m, 2g if no unit spcified it assumes gigabytes",
        :proc => Proc.new {|mem| Chef::Config[:knife][:xapi_mem] = mem } 

      # destroy/remove VM refs and exit
      def cleanup(vm_ref)
        ui.warn "Clenaing up work and exiting"
        xapi.VM.destroy(vm_ref)
        exit 1 
      end

      def run 
        server_name = @name_args[0]
        $stdout.sync = true
      
        # get the template vm we are going to build from
        template_ref = find_template( Chef::Config[:knife][:xapi_vm_template] )

        ui.msg "Cloning Guest from Template: #{h.color(template_ref, :bold, :cyan )}" 
        vm_ref = xapi.VM.clone(template_ref, server_name)  

        begin
          xapi.VM.set_name_description(vm_ref, "VM built by knife-xapi as #{server_name}")

          # configure the install repo
          repo = Chef::Config[:knife][:xapi_install_repo] || "http://isoredirect.centos.org/centos/5/os/x86_64/"
          ui.msg "Setting Install Repo: #{h.color(repo,:bold, :cyan)}"
          xapi.VM.set_other_config(vm_ref, { "install-repository" => repo } )
    
          cpus = Chef::Config[:knife][:xapi_cpus].to_s || "2"
          xapi.VM.set_VCPUs_max( vm_ref, cpus )
          xapi.VM.set_VCPUs_at_startup( vm_ref, cpus )

          memory_size = input_to_bytes( Chef::Config[:knife][:xapi_mem] || "1g" ).to_s
          ui.msg "Mem size: #{ h.color( memory_size, :cyan)}" 

          #  static-min <= dynamic-min = dynamic-max = static-max
          xapi.VM.set_memory_limits(vm_ref, memory_size, memory_size, memory_size, memory_size) 

          # 
          # setup the Boot args
          #
          boot_args = Chef::Config[:knife][:xapi_kernel_params] || "graphical utf8"
          # if no hostname param set hostname to given vm name
          boot_args << " hostname=#{server_name}" unless boot_args.match(/hostname=.+\s?/) 
          ui.msg "Setting Boot Args: #{h.color boot_args, :cyan}"
          xapi.VM.set_PV_args( vm_ref, boot_args ) 

          # TODO: validate that the vm gets a network here
          networks = @name_args[1..-1]
          # if the user has provided networks
          if networks.length >= 1  
            clear_vm_vifs( xapi.VM.get_record( vm_ref ) )
            networks.each_with_index do |net, index| 
              add_vif_by_name(vm_ref, index, net)
            end
          end

          sr_ref = find_default_sr
          if Chef::Config[:knife][:xapi_sr]
            sr_ref = get_sr_by_name( Chef::Config[:knife][:xapi_sr] ) 
          end

          if sr_ref.nil?
            ui.error "SR specified not found or can't be used Aborting"
            cleanup(vm_ref)
          end 
          ui.msg "SR: #{h.color sr_ref, :cyan} created" 

          # Create the VDI
          disk_size = Chef::Config[:knife][:xapi_disk_size] || "8g" 
          vdi_ref = create_vdi("#{server_name}-root", sr_ref, disk_size )
          # if vdi_ref is nill we need to bail/cleanup
          cleanup(vm_ref) unless vdi_ref
          ui.msg( "#{ h.color "OK", :green}" )

          # Attach the VDI to the VM
          vbd_ref = create_vbd(vm_ref, vdi_ref, 0)
          cleanup(vm_ref) unless vbd_ref 
          ui.msg( "#{ h.color "OK", :green}" )
 
          ui.msg "Provisioning new Guest: #{h.color(vm_ref, :bold, :cyan )}" 
          provisioned = xapi.VM.provision(vm_ref)

          ui.msg "Starting new Guest: #{h.color( provisioned, :cyan)} "
          
          task = xapi.Async.VM.start(vm_ref, false, true)
          wait_on_task(task) 
          ui.msg( "#{ h.color "Done!", :green}" )

        rescue Exception => e
          ui.msg "#{h.color 'ERROR:'} #{h.color( e.message, :red )}"
          # have to use join here to pass a string to highline
          puts "Nested backtrace:"
          ui.msg "#{h.color( e.backtrace.join("\n"), :yellow)}"
          
          cleanup(vm_ref)
        end
        # TODO: bootstrap
      end

    end
  end
end

