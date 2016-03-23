# Knife Xapi
This plugin gives knife the ability to create guests on a XAPI compatable hyper visor

# Installation
This plugin is distributed as a Ruby Gem. To install it, run:

    gem install knife-xapi

# Configuration
Config options are extendable in the knife.rb the folowing config options can be defined there

* __knife[:xapi_host]__ The API Host to connect to  
* __knife[:xapi_username]__ The User name to connect to the api with
* __knife[:xapi_password]__ The Password (if not set will prompt on commandline) 
* __knife[:xapi_vm_template]__ Set a default template to be used when creating Guests
* __knife[:install_repo]__ The install repo config option to set when using Xen builtin templates
* __knife[:xapi_sr]__ The Storage Repository to provision from, uses pool/hypervisor default when not set
* __knife[:xapi_disk_size]__ Default VM disk size (8g if not specified)a
* __knife[:xapi_skip_disk]__ Skip adding any aditional disk to the vm. 
* __knife[:xapi_cpus]__ The Default CPUs to provision for guests (2 if not specified)
* __knife[:xapi_mem]__  The Defaul ammount of Memory  for guests (1g if not specified)
* __knife[:kernel_params]__ Optional Boot paramaters to pass to the guest 
* __knife[:xapi_ssl_verify]__ Enable SSL Cert verification. Disabled due to xenserver not having valid certs on xapi

### These options Controll xapi guest create bootstrap

* __knife[:domain]__ Set the domainname for the guest
* __knife[:run_list]__  Bootstrap Run list comma sepparated. 
* __knife[:ssh_user]__  ssh user to login to the new vm as
* __knife[:ssh_port]__  ssh port to use
* __knife[:ssh_password]__  ssh password to use to login to the new vm
* __knife[:identity_file]__ ssh ident file
* __knife[:chef_node_name]__  node name to use for new guest chef run
* __knife[:bootstrap_version]__  version to bootstrap 
* __knife[:bootstrap_template]__ template to use 
* __knife[:template_file]__ path to a different template file you would like to use
* __knife[:environment]__ chef environment for first run
* __knife[:host_key_verify]__  true/false  Honor hostkey verification or don't
* __knife[:ping_timeout]__ Seconds to timeout while waiting for an IP to be returned from guest
* __knife[:json_attributes]__ A JSON string to be added to the first run of chef-client
* __knife[:connect_timeout]__ Seconds to timeout while trying to connect to a guest



# Usage
Note: The commands below when not specifing --host assumes that __knife[:xapi_host]__ is set in ~/.chef/knife.rb

## Guest Create 
Basic usage to create a VM from existing VM template:

    knife xapi guest create "NewBox" "Network 0"  --xapi-vm-template "MyBaseBox"   --host http://sandbox/ 

More verbose example using a kickstart file and booting the Centos 5 default template:

    knife xapi guest create "MySpiffyBox" "pub_network" --host http://sandbox/ \
    -B "dns=8.8.8.8 ks=http://192.168.6.4/repo/ks/default.ks " \
    -R http://192.168.6.5/repo/centos/5/os/x86_64 -C 4 -M 4g -D 5g 

* __-B__ Boot args where i am assigning all the centos/rhel boot args for kickstart file  and dns
* __-R__ Repo URL used by xenserver to start the net install 
* __-C__ Number of cpus for this guest
* __-M__ Memory size 
* __-D__ Disk size

### Bootstrap
Using the same basic example you can bootstrap into a specific template

     knife xapi guest create "NewBox" "public" --xapi-vm-template "MyBaseBox" --host http://sandbox/ \
       --bootstrap-template centos5-gems --ssh-user root --ssh-password mypass \
       --run-list "role[base],role[spifybox]"

## Guest Delete 
Delete is pretty simple. When there are multiple vms with a name label you should be prompted to select one

    knife xapi guest delete  testing 

If you know the UUID of the VM you can specify --uuid

    knife xapi guest delete b461c0d2-d24d-bc02-3231-711101f57b8e --uuid

## Guest List
List shows the vm's on the pool/host Ignoring Controll domains and templates. VM  State, and Ip adress as reported through the xenapi.
If you want to get the OpaqueRef, and UUID add -i or --show-id.

    knife xapi guest list  
    Name Label                 State        IP Address      
    ks_test.local              Running      10.4.1.163      
    dns01.local                Running      10.4.1.149      
    dhcp01.local               Running      10.4.1.143      
    jn_test.local              Running      10.4.1.162  

## Start/Stop Guest
You can start/stop any instance with.. start and stop commands

    knife xapi guest stop jn_test.local
    knife xapi guest start jn_test.local

## VDI Create
Create a disk on the xenserver with the specified size and name

    xapi vdi create testing -D 20g 

* -D is the short option for --xapi-disk-size
* specify the SR to use with --xapi-sr or -S 

## VDI Delete
Remove a disk. 
    
    xapi vdi delete testing 

Delete has a special cleanup mode that will interactivly prompt you if you want to clean up non attached volumes

    xapi vdi delete --interactive  

Delete also accepts a UUID  for a disk with --uuid 

## VDI List
Report on xapi VDI's 

    knife xapi vdi list
    ================================================
    VDI name: xs-tools.iso
      -UUID: bed2a28e-d68a-43d6-b8a1-2d30730b1561
      -Description: 
        -Type: user
    ================================================
    VDI name: chef-server-root
      -UUID: 159cbeb9-45c6-43e0-8631-b88d7644beae
      -Description: Root disk for chef-server-root created by jnelson with knfie xapi
        -Type: system
          -VM name: chef01.mkd.ktc
          -VM state: Running

## Net list
Output info on host/pool networks lists the MTU, the extra info and name of the network. 

    Name:  vlan1120.stage
      Info:  255.255.255.0 : 10.33.89.1-10.33.89.254
       MTU:  1500
      UUID:  73f6f18f-c1d9-664b-d4bb-7673ea0fc2a1

# Help
Every command should accept --help and display arguments that it accepts (as all knife plugins do) 

    knife xapi --help

    knife xapi guest create --help 

