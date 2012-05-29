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
      require 'timeout'

      deps do
        require 'chef/knife/bootstrap'
        Chef::Knife::Bootstrap.load_deps
      end

      banner "knife xapi guest create NAME [NETWORKS] (options)"

      option :vm_template,
        :short => "-T Template Name Label",
        :long => "--xapi-vm-template",
        :description => "xapi template name to create from. accepts an string or regex",
        :proc => Proc.new { |template| Chef::Config[:knife][:xapi_vm_template] = template }

      option :domain,
        :short => "-f Name",
        :long => "--domain Name",
        :description => "the domain name for the guest",
        :proc => Proc.new { |domain| Chef::Config[:knife][:xapi_domainname] = domain }

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

      option :chef_node_name,
        :short => "-N NAME",
        :long => "--node-name NAME",
        :description => "The Chef node name for your new node"

      option :ssh_key_name,
        :short => "-S KEY",
        :long => "--ssh-key KEY",
        :description => "The SSH key id",
        :proc => Proc.new { |key| Chef::Config[:knife][:xapi_ssh_key_id] = key }

      option :ssh_user,
        :short => "-x USERNAME",
        :long => "--ssh-user USERNAME",
        :description => "The ssh username",
        :default => "root"

      option :ssh_password,
        :short => "-P PASSWORD",
        :long => "--ssh-password PASSWORD",
        :description => "The ssh password"

      option :ssh_port,
        :short => "-p PORT",
        :long => "--ssh-port PORT",
        :description => "The ssh port",
        :default => "22",
        :proc => Proc.new { |key| Chef::Config[:knife][:ssh_port] = key }

      option :bootstrap_version,
        :long => "--bootstrap-version VERSION",
        :description => "The version of Chef to install",
        :proc => Proc.new { |v| Chef::Config[:knife][:bootstrap_version] = v }

      option :distro,
        :short => "-d DISTRO",
        :long => "--distro DISTRO",
        :description => "Bootstrap a distro using a template",
        :proc => Proc.new { |d| Chef::Config[:knife][:distro] = d },
        :default => "ubuntu10.04-gems"

      option :template_file,
        :short => "-F FILEPATH",
        :long => "--template-file TEMPLATE",
        :description => "Full path to location of template to use",
        :proc => Proc.new { |t| Chef::Config[:knife][:template_file] = t },
        :default => false
     
      option :run_list,
        :short => "-r RUN_LIST",
        :long => "--run-list RUN_LIST",
        :description => "Comma separated list of roles/recipes to apply",
        :proc => lambda { |o| o.split(/[\s,]+/) },
        :default => [] 

      def tcp_test_ssh(hostname)
        tcp_socket = TCPSocket.new(hostname, config[:ssh_port])
        readable = IO.select([tcp_socket], nil, nil, 5)
        if readable
          Chef::Log.debug("sshd accepting connections on #{hostname}, banner is #{tcp_socket.gets}")
          yield
          true
        else
          false
        end
      rescue SocketError
        sleep 2
        false
      rescue Errno::ETIMEDOUT
        false
      rescue Errno::EPERM
        false
      rescue Errno::ECONNREFUSED
        sleep 2
        false
      # This happens on EC2 quite often
      rescue Errno::EHOSTUNREACH
        sleep 2
        false
      ensure
        tcp_socket && tcp_socket.close
      end

      def get_guest_ip(vm_ref)
        begin
          timeout(480) do
            ui.msg "Waiting for guest ip address" 
            guest_ip = ""
            while guest_ip.empty?
              print(".") 
              sleep  @initial_sleep_delay ||=  10
              vgm =  xapi.VM.get_guest_metrics(vm_ref)
              next if "OpaqueRef:NULL" == vgm
              networks = xapi.VM_guest_metrics.get_networks(vgm)
              if networks.has_key?("0/ip")
                guest_ip = networks["0/ip"]
              end
            end
            puts "\n" 
            return guest_ip
          end 
        rescue Timeout::Error
          ui.msg "Timeout waiting for XAPI to report IP address "
        end
      end

      # destroy/remove VM refs and exit
      def cleanup(vm_ref)
        ui.warn "Cleaning up work and exiting"
        # shutdown and dest
        unless xapi.VM.get_power_state(vm_ref) == "Halted"
          print "Shutting down Guest"
          task = xapi.Async.VM.hard_shutdown(vm_ref)
          wait_on_task(task)
          print " #{h.color "Done", :green} \n"
        end

        print "Destroying Guest"
        task = xapi.Async.VM.destroy(vm_ref)
        wait_on_task(task)
        print " #{h.color "Done", :green} \n"
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
          domainname = Chef::Config[:knife][:xapi_domainname] || ""

          # if no hostname param set hostname to given vm name
          boot_args << " hostname=#{server_name}" unless boot_args.match(/hostname=.+\s?/) 
          # if domainname is supplied we put that in there as well
          boot_args << " domainname=#{domainname}" unless boot_args.match(/domainname=.+\s?/) 

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

          ui.msg "Starting new Guest #{h.color( provisioned, :cyan)} "
          
          task = xapi.Async.VM.start(vm_ref, false, true)
          wait_on_task(task) 
          ui.msg( "#{ h.color "Done!", :green}" )

          exit 0 unless locate_config_value(:run_list)       
        rescue Exception => e
          ui.msg "#{h.color 'ERROR:'} #{h.color( e.message, :red )}"
          # have to use join here to pass a string to highline
          puts "Nested backtrace:"
          ui.msg "#{h.color( e.backtrace.join("\n"), :yellow)}"
          
          cleanup(vm_ref)
        end

        guest_addr = get_guest_ip(vm_ref)
        if guest_addr.nil? or guest_addr.empty?
          ui.msg("ip seems wrong using host+domain name instead")
          guest_addr = "#{host_name}.#{domainname}"
        end
        ui.msg "Trying to connect to guest @ #{guest_addr} "

        begin
          timeout(480) do
            print(".") until tcp_test_ssh(guest_addr) {
              sleep @initial_sleep_delay ||=  10
              puts("done")
            }
          end
        rescue Timeout::Error
          ui.msg "Timeout trying to login cleaning up"
          cleanup(vm_ref)
        end


        begin 
          server_name << ".#{domainname}" unless domainname.empty?
          bootstrap = Chef::Knife::Bootstrap.new
          bootstrap.name_args = [ guest_addr ]
          bootstrap.config[:run_list] = config[:run_list]
          bootstrap.config[:ssh_user] = config[:ssh_user]
          bootstrap.config[:ssh_port] = config[:ssh_port]
          bootstrap.config[:ssh_password] = config[:ssh_password]
          bootstrap.config[:identity_file] = config[:identity_file]
          bootstrap.config[:chef_node_name] = config[:chef_node_name] || server_name
          bootstrap.config[:bootstrap_version] = locate_config_value(:bootstrap_version)
          bootstrap.config[:distro] = locate_config_value(:distro)
          bootstrap.config[:use_sudo] = true unless config[:ssh_user] == 'root'
          bootstrap.config[:template_file] = locate_config_value(:template_file)
          bootstrap.config[:environment] = config[:environment]
          bootstrap.config[:host_key_verify] = false
          bootstrap.config[:run_list] = config[:run_list]
          
          bootstrap.run
        rescue Exception => e 
          ui.msg "#{h.color 'ERROR:'} #{h.color( e.message, :red )}"
          puts "Nested backtrace:"
          ui.msg "#{h.color( e.backtrace.join("\n"), :yellow)}"
          cleanup(vm_ref)
        end

      end

    end
  end
end

