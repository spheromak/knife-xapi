# Xapi Base Module
#
# Description:: Setup the Session and auth for xapi 
#   other common methods used for talking with the xapi
#
# Author:: Jesse Nelson <spheromak@gmail.com>
#
# Copyright:: Copyright (c) 2012, Jesse Nelson
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

# ruby 1.8.7 doesn't like ||= with  Constants
unless defined?(XAPI_TEMP_REGEX)
  XAPI_TEMP_REGEX = /^CentOS 5.*\(64-bit\)/
end

require 'chef/knife'
require 'units/standard'

class Chef::Knife
    module XapiBase

    def self.included(includer)
      includer.class_eval do
        deps do
          require 'xenapi'
          require 'highline'
          require 'highline/import'
          require 'readline'  
        end 

        option :host,
          :short => "-h SERVER_URL",
          :long => "--host SERVER_URL",
          :description => "The url to the xenserver, http://somehost.local.lan/",
          :proc => Proc.new { |host| Chef::Config[:knife][:xenserver_host] = host }

        option :xenserver_password,
          :short => "-K PASSWORD",
          :long => "--xenserver-password PASSWORD",
          :description => "Your xenserver password",
          :proc => Proc.new { |key| Chef::Config[:knife][:xenserver_password] = key }

        option :xenserver_username,
          :short => "-A USERNAME",
          :long => "--xenserver-username USERNAME",
          :description => "Your xenserver username",
          :proc => Proc.new { |username| Chef::Config[:knife][:xenserver_username] = username }      
      end
    end

    # highline setup
    def h
      @highline ||= ui.highline
    end 

    # setup and return an authed xen api instance
    def xapi
      @xapi ||= begin 

        session = XenApi::Client.new( Chef::Config[:knife][:xenserver_host] )
        
        # get the password from the user
        password = Chef::Config[:knife][:xenserver_password] || nil
        username = Chef::Config[:knife][:xenserver_username] || "root"
        if password.nil?  or password.empty?
          password = ask("Enter password for user #{username}:  " ) { |input| input.echo = "*" }
        end
        session.login_with_password(username, password) 

        session
      end
    end

    # get template by name_label
    def get_template(template)
      xapi.VM.get_by_name_label(template).first
    end

    #
    # find a template matching what the user provided 
    # 
    # returns a ref to the vm or nil if nothing found
    # 
    def find_template(template=XAPI_TEMP_REGEX)
      # if we got a string then try to find that template exact 
      #  if no exact template matches, search
      if template.is_a?(String)
        found = get_template(template)
        return found if found
      end

      #  make sure our nil template gets set to default
      if template.nil?
        template = XAPI_TEMP_REGEX
      end 

      Chef::Log.debug "Name: #{template.class}"
      # quick and dirty string to regex
      unless template.is_a?(Regexp)
        template = /#{template}/ 
      end

      # loop over all vm's and find the template 
      # Wish there was a better API method for this, and there might be
      #  but i couldn't find it
      Chef::Log.debug "Using regex: #{template}"
      xapi.VM.get_all_records().each_value do |vm|
        if vm["is_a_template"] and  vm["name_label"] =~ template
          Chef::Log.debug "Matched: #{h.color(vm["name_label"], :yellow )}"
          found = vm # we're gonna go with the last found 
        end
      end

      # ensure return values
      if found
        puts "Using Template: #{h.color(found["name_label"], :cyan)}"
        return get_template(found["name_label"]) # get the ref to this one
      end
      return nil
    end
 
    # present a list of options for a user to select 
    # return the selected item
    def user_select(items)
      choose do |menu|
        menu.index  = :number
        menu.prompt = "Please Choose One:"
        menu.select_by =  :index_or_name
        items.each do |item|
          menu.choice item.to_sym do |command| 
            say "Using: #{command}" 
            selected = command.to_s
          end
        end
        menu.choice :exit do exit 1 end
      end
    end

    # generate a random mac address
    def generate_mac 
      ("%02x"%(rand(64)*4|2))+(0..4).inject(""){|s,x|s+":%02x"%rand(256)}
    end

    # add a new vif
    def add_vif_by_name(vm_ref, dev_num, net_name)
      puts "Looking up vif for: #{h.color(net_name, :cyan)}"
      network_ref = xapi.network.get_by_name_label(net_name).first
      if network_ref.nil? 
        ui.warn "#{h.color(net_name,:red)} not found, moving on"
        return 
      end

      mac = generate_mac
      puts "Provisioning:  #{h.color(net_name, :cyan)}, #{h.color(mac,:green)}, #{h.color(network_ref, :yellow)}"

      vif = { 
        'device'  => dev_num.to_s,
        'network' => network_ref,
        'VM'  => vm_ref,
        'MAC' => generate_mac,
        'MTU' => "1500",
        "other_config" => {},
        "qos_algorithm_type"   => "",
        "qos_algorithm_params" => {}
      }
      vif_ref = xapi.VIF.create(vif)
      vif_ref
    end

    # remove all vifs on a record
    def clear_vm_vifs(record)
      record["VIFs"].each do |vif|
        Chef::Log.debug "Removing vif: #{h.color(vif, :red, :bold)}"
        xapi.VIF.destroy(vif)
      end
    end

    # returns sr_ref to the default sr on pool
    def find_default_sr()
      xapi.pool.get_default_SR( xapi.pool.get_all()[0] ) 
    end

    # return an SR record from the name_label
    def get_sr_by_name(name)
      sr_ref = xapi.SR.get_by_name_label(name)
      if sr_ref.empty? or sr_ref.nil?
        ui.error "SR name #{h.color( name ) } not found"
        return nil
      end
      sr = xapi.SR.get_record( sr_ref )
    end

    # convert 1g/1m/1t to bytes
    # rounds to whole numbers
    def input_to_bytes(size)
      case size
      when /g|gb/i
        size.to_i.gb.to_bytes.to_i
      when /m|mb/i
        size.to_i.mb.to_bytes.to_i
      when /t|tb/i
        size.to_i.tb.to_bytes.to_i
      else
        size.to_i.gb.to_bytes.to_i
      end
    end

    # create a vdi return ref
    def create_vdi(name, sr_ref, size)
      vdi_record = {
        "name_label" => "#{name}",
        "name_description" => "Root disk for #{name} created by knfie xapi",
        "SR" => sr_ref,
        "virtual_size" => input_to_bytes(size).to_s,
        "type" => "system",
        "sharable" => false,
        "read_only" => false,
        "other_config" => {},
      }
    
      # Async create the VDI
      task = xapi.Async.VDI.create(vdi_record)
      ui.msg "waiting for VDI Create"
      vdi_ref = get_task_ref(task)
    end


    # sit and wait for taks to exit pending state
    def wait_on_task(task)
      while xapi.task.get_status(task) == "pending"
        progress = xapi.task.get_progress(task)
        sleep 1
      end
    end
   
    # return the opaque ref of the task that was run by a task record if it succeded.
    # else it returns nil 
    def get_task_ref(task)
      wait_on_task(task)
      case xapi.task.get_status(task) 
      when "success"
        # xapi task record returns result as  <value>OpaqueRef:....</value>  
        # we want the ref. this way it will work if they fix it to return jsut the ref
        ref = xapi.task.get_result(task).match(/OpaqueRef:[^<]+/).to_s
        #cleanup our task
        xapi.task.destroy(task)
        return ref
      else 
        ui.msg( "#{h.color 'ERROR:', :red } Task returned: #{xapi.task.get_result(task)}"   )
        return nil
      end
    end


    # create vbd and return a ref 
    def create_vbd(vm_ref, vdi_ref, position)
      vbd_record = {
        "VM" => vm_ref,
        "VDI" => vdi_ref,
        "empty" => false,
        "other_config" => {"owner"=>""},
        "userdevice" => position.to_s,
        "bootable" => true,
        "mode" => "RW",
        "qos_algorithm_type" => "",
        "qos_algorithm_params" => {},
        "qos_supported_algorithms" => [],
        "type" => "Disk"
      }

      task = xapi.Async.VBD.create(vbd_record)
      ui.msg "Waiting for VBD create"
      vbd_ref = get_task_ref(task) 
    end

  end
end
