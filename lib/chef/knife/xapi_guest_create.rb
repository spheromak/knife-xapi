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
      require 'timeout'
      include Chef::Knife::XapiBase

      Chef::Knife::XapiBase.set_defaults( {
        :domain => "",
        :ssh_user => "root",
        :ssh_port => "22",
        :install_repo =>  "http://isoredirect.centos.org/centos/6/os/x86_64/",
        :kernel_params => "graphical utf8",
        :xapi_disk_size => "8g",
        :xapi_cpus => "1",
        :xapi_mem => "1g",
        :bootstrap_template => "ubuntu10.04-gems",
        :template_file => false,
        :run_list => [],
        :json_attributes => {}
      })

      deps do
        require 'chef/knife/bootstrap'
        Chef::Knife::Bootstrap.load_deps
      end

      banner "knife xapi guest create NAME [NETWORKS] (options)"

      option :xapi_vm_template,
        :short => "-T Template Name Label",
        :long => "--xapi-vm-template",
        :proc => Proc.new { |key| Chef::Config[:knife][:xapi_vm_template] = key },
        :description => "xapi template name to create from. accepts an string or regex"

      option :install_repo,
        :short => "-R If you're using a builtin template you will need to specify a repo url",
        :long => "--install-repo",
        :description => "Install repo for this template (if needed)",
        :proc => Proc.new { |key| Chef::Config[:knife][:install_repo] = key }

      option :xapi_sr,
        :short => "-S Storage repo to provision VM from",
        :long  => "--xapi-sr",
        :proc => Proc.new { |key| Chef::Config[:knife][:xapi_sr] = key },
        :description => "The Xen SR to use, If blank will use pool/hypervisor default"

      option :kernel_params,
        :short => "-B Set of kernel boot params to pass to the vm",
        :long => "--kernel-params",
        :description => "You can add more boot options to the vm e.g.: \"ks='http://foo.local/ks'\"",
        :proc => Proc.new { |key| Chef::Config[:knife][:kernel_params] = key }

      option :xapi_disk_size,
        :short => "-D Size of disk. 1g 512m etc",
        :long  =>  "--xapi-disk-size",
        :description => "The size of the root disk, use 'm' 'g' 't' if no unit specified assumes g",
        :proc => Proc.new { |key| Chef::Config[:knife][:xapi_disk_size] = key.to_s }

      option :xapi_cpus,
        :short => "-C Number of VCPUs to provision",
        :long =>  "--xapi-cpus",
        :description => "Number of VCPUS this vm should have 1 4 8 etc",
        :proc => Proc.new { |key| Chef::Config[:knife][:xapi_cpus] = key.to_s }

      option :xapi_mem,
        :short => "-M Ammount of memory to provision",
        :long => "--xapi-mem",
        :description => "Ammount of memory the VM should have specify with m g etc 512m, 2g if no unit spcified it assumes gigabytes",
        :proc => Proc.new { |key| Chef::Config[:knife][:xapi_mem] = key.to_s }

      option :chef_node_name,
        :short => "-N NAME",
        :long => "--node-name NAME",
        :description => "The Chef node name for your new node"

      option :ssh_key_name,
        :short => "-S KEY",
        :long => "--ssh-key KEY",
        :proc => Proc.new { |key| Chef::Config[:knife][:ssh_key_name] = key },
        :description => "The SSH key id"

      option :ssh_user,
        :short => "-x USERNAME",
        :long => "--ssh-user USERNAME",
        :description => "The ssh username",
        :proc => Proc.new { |key| Chef::Config[:knife][:ssh_user] = key }

      option :ssh_password,
        :short => "-P PASSWORD",
        :long => "--ssh-password PASSWORD",
        :proc => Proc.new { |key| Chef::Config[:knife][:ssh_password] = key },
        :description => "The ssh password"

      option :ssh_port,
        :short => "-p PORT",
        :long => "--ssh-port PORT",
        :description => "The ssh port"

      option :bootstrap_version,
        :long => "--bootstrap-version VERSION",
        :description => "The version of Chef to install"

      option :bootstrap_template,
        :short => "-d Template Name",
        :long => "--bootstrap-template Template Name",
        :description => "Bootstrap using a specific template"

      option :template_file,
        :short => "-F FILEPATH",
        :long => "--template-file TEMPLATE",
        :description => "Full path to location of template to use"

      option :json_attributes,
        :short => "-j JSON_ATTRIBS",
        :long => "--json-attributes",
        :description => "A JSON string to be added to the first run of chef-client",
        :proc => lambda { |o| JSON.parse(o) }

      option :run_list,
        :short => "-r RUN_LIST",
        :long => "--run-list RUN_LIST",
        :description => "Comma separated list of roles/recipes to apply",
        :proc => lambda { |o| o.split(/[\s,]+/) }

      def tcp_test_ssh(hostname)
        tcp_socket = TCPSocket.new(hostname, locate_config_value(:ssh_port) )
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

      def wait_for_guest_ip(vm_ref)
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
        domainname = locate_config_value(:domain)
        if domainname.empty?
          fqdn = server_name
        else
          fqdn = "#{server_name}.#{domainname}"
        end

        # get the template vm we are going to build from
        template_ref = find_template( locate_config_value(:xapi_vm_template) )

        Chef::Log.debug "Cloning Guest from Template: #{h.color(template_ref, :bold, :cyan )}"
        vm_ref = xapi.VM.clone(template_ref, fqdn)

        # TODO: lift alot of this
        begin
          xapi.VM.set_name_description(vm_ref, "VM from knife-xapi as #{server_name} by #{ENV['USER']}")

          # configure the install repo
          repo = locate_config_value(:install_repo)
          xapi.VM.set_other_config(vm_ref, { "install-repository" => repo } )


          cpus = locate_config_value( :xapi_cpus ).to_s

          xapi.VM.set_VCPUs_max( vm_ref, cpus )
          xapi.VM.set_VCPUs_at_startup( vm_ref, cpus )

          memory_size = input_to_bytes( locate_config_value(:xapi_mem) ).to_s
          #  static-min <= dynamic-min = dynamic-max = static-max
          xapi.VM.set_memory_limits(vm_ref, memory_size, memory_size, memory_size, memory_size)

          #
          # setup the Boot args
          #
          boot_args = locate_config_value(:kernel_params)

          # if no hostname param set hostname to given vm name
          boot_args << " hostname=#{server_name}" unless boot_args.match(/hostname=.+\s?/)
          # if domainname is supplied we put that in there as well
          boot_args << " dnsdomain=#{domainname}" unless boot_args.match(/dnsdomain=.+\s?/)

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

          if locate_config_value(:xapi_sr)
            sr_ref = get_sr_by_name( locate_config_value(:xapi_sr) )
          else
            sr_ref = find_default_sr
          end

          if sr_ref.nil?
            ui.error "SR specified not found or can't be used Aborting"
            cleanup(vm_ref)
          end
          Chef::Log.debug "SR: #{h.color sr_ref, :cyan}"

          # Create the VDI
          vdi_ref = create_vdi("#{server_name}-root", sr_ref, locate_config_value(:xapi_disk_size) )
          cleanup(vm_ref) unless vdi_ref

          # Attach the VDI to the VM
          vbd_ref = create_vbd(vm_ref, vdi_ref, 0)
          cleanup(vm_ref) unless vbd_ref

          ui.msg "Provisioning new Guest: #{h.color(fqdn, :bold, :cyan )}"
          ui.msg "Boot Args: #{h.color boot_args,:bold, :cyan}"
          ui.msg "Install Repo: #{ h.color(repo,:bold, :cyan)}"
          ui.msg "Memory: #{ h.color( locate_config_value(:xapi_mem).to_s, :bold, :cyan)}"
          ui.msg "CPUs:   #{ h.color( locate_config_value(:xapi_cpus).to_s, :bold, :cyan)}"
          ui.msg "Disk:   #{ h.color( locate_config_value(:xapi_disk_size).to_s, :bold, :cyan)}"
          provisioned = xapi.VM.provision(vm_ref)

          ui.msg "Starting new Guest #{h.color( provisioned, :cyan)} "
          task = xapi.Async.VM.start(vm_ref, false, true)
          wait_on_task(task)
          ui.msg( "#{ h.color "OK!", :green}" )

          exit 0 unless locate_config_value(:run_list)
        rescue Exception => e
          ui.msg "#{h.color 'ERROR:'} #{h.color( e.message, :red )}"
          # have to use join here to pass a string to highline
          puts "Nested backtrace:"
          ui.msg "#{h.color( e.backtrace.join("\n"), :yellow)}"

          cleanup(vm_ref)
        end

        if locate_config_value(:run_list).empty? or ! locate_config_value(:template_file)
          exit 0
        end

        guest_addr = wait_for_guest_ip(vm_ref)
        if guest_addr.nil? or guest_addr.empty?
          ui.msg("ip seems wrong using host+domain name instead")
          guest_addr = "#{server_name}.#{domainname}"
        end
        ui.msg "Trying to connect to guest @ #{guest_addr} "

        begin
          timeout(480) do
            print(".") until tcp_test_ssh(guest_addr) {
              sleep @initial_sleep_delay ||=  10
              ui.msg( "#{ h.color "OK!", :green}" )
            }
          end
        rescue Timeout::Error
          ui.msg "Timeout trying to login cleaning up"
          cleanup(vm_ref)
        end


        begin
          bootstrap = Chef::Knife::Bootstrap.new
          bootstrap.name_args = [ guest_addr ]
          bootstrap.config[:run_list] = locate_config_value(:run_list)
          bootstrap.config[:ssh_user] = locate_config_value(:ssh_user)
          bootstrap.config[:ssh_port] = locate_config_value(:ssh_port)
          bootstrap.config[:ssh_password] = locate_config_value(:ssh_password)
          bootstrap.config[:identity_file] = locate_config_value(:identity_file)
          bootstrap.config[:chef_node_name] = config[:chef_node_name] || fqdn
          bootstrap.config[:bootstrap_version] = locate_config_value(:bootstrap_version)
          bootstrap.config[:first_boot_attributes] = locate_config_value(:json_attributes)
          bootstrap.config[:distro] = locate_config_value(:bootstrap_template)
          bootstrap.config[:use_sudo] = true unless locate_config_value(:ssh_user) == 'root'
          bootstrap.config[:template_file] = locate_config_value(:template_file)
          bootstrap.config[:environment] = config[:environment]
          bootstrap.config[:host_key_verify] = false
          bootstrap.config[:run_list] = locate_config_value(:run_list)

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

