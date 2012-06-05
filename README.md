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
* __knife[:vm_template]__ Set a default template to be used when creating Guests
* __knife[:install_repo]__ The install repo config option to set when using Xen builtin templates
* __knife[:xapi_sr]__ The Storage Repository to provision from, uses pool/hypervisor default when not set
* __knife[:xapi_disk_size]__ Default VM disk size (8g if not specified)
* __knife[:xapi_cpus]__ The Default CPUs to provision for guests (2 if not specified)
* __knife[:xapi_mem]__  The Defaul ammount of Memory  for guests (1g if not specified)
* __knife[:kernel_params]__ Optional Boot paramaters to pass to the guest 

### These options Controll xapi guest create bootstrap
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


# Usage
## Create VM
Basic usage to create a VM from existing VM template:

    knife xapi guest create "NewBox" "public"  --xapi-vm-template "MyBaseBox"   --host http://sandbox/ 


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

## Delete 
Delete is pretty simple. When there are multiple vms with a name label you should be prompted to select one

    knife xapi guest delete  testing 

If you know the UUID of the VM you can specify --uuid

    knife xapi guest delete b461c0d2-d24d-bc02-3231-711101f57b8e --uuid

## List
List shows the vm's on the pool/host Ignoring Controll domains and templates. VM  State, OpaqueRef, and UUID are displayed which can be usefull

    knife xapi guest list
    Name Label                 State         Ref                                             UUID                                 
    test-server                Running       OpaqueRef:82065b80-55ff-63ce-ef89-6b33fb5fd272  9b0a0afa-5573-7875-b787-47fbfa2548a4 
    tester                     Halted        OpaqueRef:2d239fbd-bff6-4e60-f675-e1d2530199d2  de760651-2db8-6f81-0783-7b8364f591fd 
    test-client                Halted        OpaqueRef:e4bbd801-c9be-e355-2a22-2ca468a90a81  35156957-45f4-02f8-6de9-6adbcd5e0c6d 
    test-client                Running       OpaqueRef:f5b562f8-a493-f535-335e-ae70b3177869  f46e4d6b-bd9e-e47b-5f0d-b849ff75c5ef 

# Command Line Arguments
    $ knife xapi guest create --help                                                                                                           ~/git/knife-xapi/lib/chef/knife ▸▸▸▸▸▸▸▸▸▸
    knife xapi guest create NAME [NETWORKS] (options)
        --bootstrap-template Template Name
                                     Bootstrap using a specific template
        --bootstrap-version VERSION  The version of Chef to install
    -N, --node-name NAME             The Chef node name for your new node
    -s, --server-url URL             Chef Server URL
    -k, --key KEY                    API Client Key
        --[no-]color                 Use colored output, defaults to enabled
    -c, --config CONFIG              The configuration file to use
        --defaults                   Accept default values for all questions
    -d, --disable-editing            Do not open EDITOR, just accept the data as is
    -f, --domain Name                the domain name for the guest
    -e, --editor EDITOR              Set the editor to use for interactive commands
    -E, --environment ENVIRONMENT    Set the Chef environment
        --format FORMAT              Which format to use for output
    -R If you're using a builtin template you will need to specify a repo url,
        --xapi-install-repo          Install repo for this template (if needed)
    -B Set of kernel boot params to pass to the vm,
        --kernel-params         You can add more boot options to the vm e.g.: "ks='http://foo.local/ks'"
    -u, --user USER                  API Client Username
        --print-after                Show the data after a destructive operation
    -r, --run-list RUN_LIST          Comma separated list of roles/recipes to apply
        --ssh-key KEY                The SSH key id
    -P, --ssh-password PASSWORD      The ssh password
    -p, --ssh-port PORT              The ssh port
    -x, --ssh-user USERNAME          The ssh username
    -F, --template-file TEMPLATE     Full path to location of template to use
    -V, --verbose                    More verbose output. Use twice for max verbosity
    -v, --version                    Show chef version
    -T Template Name Label,          xapi template name to create from. accepts an string or regex
        --xapi-vm-template
    -C Number of VCPUs to provision, Number of VCPUS this vm should have 1 4 8 etc
        --xapi-cpus
    -D Size of disk. 1g 512m etc,    The size of the root disk, use 'm' 'g' 't' if no unit specified assumes g
        --xapi-disk-size
    -h, --host SERVER_URL            The url to the xenserver, http://somehost.local.lan/
    -M Ammount of memory to provision,
        --xapi-mem                   Ammount of memory the VM should have specify with m g etc 512m, 2g if no unit spcified it assumes gigabytes
    -K, --xapi-password PASSWORD     Your xenserver password
    -S Storage repo to provision VM from,
        --xapi-sr                    The Xen SR to use, If blank will use pool/hypervisor default
    -A, --xapi-username USERNAME     Your xenserver username
    -y, --yes                        Say yes to all prompts for confirmation
        --help                       Show this message
