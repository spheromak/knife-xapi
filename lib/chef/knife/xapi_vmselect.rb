
class Chef::Knife
  module XapiVmSelect
    def self.included(includer)
      includer.class_eval do
        option :uuid,
               short: '-U',
               long: '--uuid',
               description: 'Treat the label as a UUID not a name label'
      end
    end

    def select_vm(name)
      if name.nil?
        ui.msg 'Must Provide VM Name'
        ui.msg 'Usage: ' + banner
        exit 1
      end

      vms = []
      if config[:uuid]
        vms << xapi.VM.get_by_uuid(name).flatten
      else
        vms << xapi.VM.get_by_name_label(name).flatten
      end
      vms.flatten!

      if vms.empty?
        ui.msg ui.color "could not find vm named #{name}", :red
        exit 1
      end

      if vms.length > 1
        vm = user_select(vms)
        if vm == :all
          return vms
        end
      else
        vm = vms.first
      end
      vm
    end
  end
end
