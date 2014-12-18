module XenApi #:nodoc:
  module Errors #:nodoc:
    # Generic errror case, all XenApi exceptions inherit from this for ease of catching
    class GenericError < RuntimeError
      # The raw error description according to the server, typically an array
      attr_reader :description

      def initialize(*args, &block)
        @description = args[0]
        args[0] = args[0].inspect unless args[0].is_a? String || args[0].nil?
        super(*args, &block)
      end
    end

    # The bootloader returned an error.
    #
    # Raised by
    # - VM.start
    # - VM.start_on
    class BootloaderFailed < GenericError; end

    # The device is not currently attached
    #
    # Raised by
    # - VBD.unplug
    class DeviceAlreadyDetached < GenericError; end

    # The VM rejected the attempt to detach the device.
    #
    # Raised by
    # - VBD.unplug
    class DeviceDetachRejected < GenericError; end

    # Some events have been lost from the queue and cannot be retrieved.
    #
    # Raised by
    # - event.next
    class EventsLost < GenericError; end

    # This operation cannot be performed because it would invalidate VM
    #  failover planning such that the system would be unable to guarantee
    # to restart protected VMs after a Host failure.
    #
    # Raised by
    # - VM.set_memory_static_max
    class HAOperationWouldBreakFailoverPlan < GenericError; end

    # The host can not be used as it is not the pool master. The data
    # contains the location of the current designated pool master.
    #
    # Raised by
    # - sesssion.login_with_password
    class HostIsSlave < GenericError; end

    # The host name is invalid
    #
    # Raised by
    # - host.set_hostname_live
    class HostNameInvalid < GenericError; end

    # Not enough host memory is available to perform this operation
    #
    # Raised by
    # - VM.assert_can_boot_here
    class HostNotEnoughFreeMemory < GenericError; end

    # You tried to create a VLAN or tunnel on top of a tunnel access
    # PIF - use the underlying transport PIF instead.
    #
    # Raised by
    # - tunnel.create
    class IsTunnelAccessPIF < GenericError; end

    # The host joining the pool cannot contain any shared storage.
    #
    # Raised by
    # - pool.join
    class JoiningHostCannotContainSharedSRs < GenericError; end

    # This operation is not allowed under your license.
    # Please contact your support representative.
    #
    # Raised by
    # - VM.start
    class LicenceRestriction < GenericError; end

    # There was an error processing your license. Please contact
    # your support representative.
    #
    # Raised by
    # - host.license_apply
    class LicenseProcessingError < GenericError; end

    # There were no hosts available to complete the specified operation.
    #
    # Raised by
    # - VM.start
    class NoHostsAvailable < GenericError; end

    # This operation needs the OpenVSwitch networking backend to be
    # enabled on all hosts in the pool.
    #
    # Raised by
    # - tunnel.create
    class OpenvswitchNotActive < GenericError; end

    # You attempted an operation that was not allowed.
    #
    # Raised by
    # - task.cancel
    # - VM.checkpoint
    # - VM.clean_reboot
    # - VM.clean_shutdown
    # - VM.clone
    # - VM.copy
    # - VM.hard_reboot
    # - VM.hard_shutdown
    # - VM.pause
    # - VM.pool_migrate
    # - VM.provision
    # - VM.resume
    #  - VM.resume_on
    # - VM.revert
    # - VM.snapshot
    # - VM.snapshot_with_quiesce
    # - VM.start
    # - VM.start_on
    # - VM.suspend
    # - VM.unpause
    class OperationNotAllowed < GenericError; end

    # Another operation involving the object is currently in progress
    #
    # Raised by
    # - VM.clean_reboot
    # - VM.clean_shutdown
    # - VM.hard_reboot
    # - VM.hard_shutdown
    # - VM.pause
    # - VM.pool_migrate
    # - VM.start
    # - VM.start_on
    # - VM.suspend
    class OtherOperationInProgress < GenericError; end

    # You tried to destroy a PIF, but it represents an aspect of the physical
    # host configuration, and so cannot be destroyed. The parameter echoes the
    # PIF handle you gave.
    #
    # Raised by
    # - PIF.destroy
    # @deprecated the PIF.destroy method is deprecated in XenServer 4.1 and replaced
    # by VLAN.destroy and Bond.destroy
    class PIFIsPhysical < GenericError; end

    # Operation cannot proceed while a tunnel exists on this interface.
    #
    # Raised by
    # - PIF.forget
    class PIFTunnelStillExists < GenericError; end

    # The credentials given by the user are incorrect, so access has been
    # denied, and you have not been issued a session handle.
    #
    # Raised by
    # - session.login_with_password
    class SessionAuthenticationFailed < GenericError; end

    # This session is not registered to receive events. You must call
    # event.register before event.next. The session handle you are
    # using is echoed.
    #
    # Raised by
    # - event.next
    class SessionNotRegistered < GenericError; end

    # The SR is full. Requested new size exceeds the maximum size
    #
    # Raised by
    # - VM.checkpoint
    # - VM.clone
    # - VM.copy
    # - VM.provision
    # - VM.revert
    # - VM.snapshot
    # - VM.snapshot_with_quiesce
    class SRFull < GenericError; end

    # The SR is still connected to a host via a PBD. It cannot be destroyed.
    #
    # Raised by
    # - SR.destroy
    # - SR.forget
    class SRHasPDB < GenericError; end

    # The SR backend does not support the operation (check the SR's allowed operations)
    #
    # Raised by
    # - VDI.introduce
    # - VDI.update
    class SROperationNotSupported < GenericError; end

    # The SR could not be connected because the driver was not recognised.
    #
    # Raised by
    # - PBD.plug
    # - SR.create
    class SRUnknownDriver < GenericError; end

    # The tunnel transport PIF has no IP configuration set.
    #
    # Raised by
    # - PIF.plug
    # - tunnel.create
    class TransportPIFNotConfigured < GenericError; end

    # The requested bootloader is unknown
    #
    # Raised by
    # - VM.start
    # - VM.start_on
    class UnknownBootloader < GenericError; end

    # Operation could not be performed because the drive is empty
    #
    # Raised by
    # - VBD.eject
    class VBDIsEmpty < GenericError; end

    # Operation could not be performed because the drive is not empty
    #
    # Raised by
    # - VBD.insert
    class VBDNotEmpty < GenericError; end

    # Media could not be ejected because it is not removable
    #
    # Raised by
    # - VBD.eject
    # - VBD.insert
    class VBDNotRemovableMedia < GenericError; end

    # You tried to create a VLAN, but the tag you gave was invalid --
    # it must be between 0 and 4094. The parameter echoes the VLAN tag you gave.
    #
    # Raised by
    # - PIF.create_VLAN (deprecated)
    # - pool.create_VLAN (deprecated)
    # - pool.create_VLAN_from_PIF
    class VlanTagInvalid < GenericError; end

    # You attempted an operation on a VM that was not in an appropriate
    # power state at the time; for example, you attempted to start a VM
    # that was already running. The parameters returned are the VM's
    # handle, and the expected and actual VM state at the time of the call.
    #
    # Raised by
    # - VM.checkpoint
    # - VM.clean_reboot
    # - VM.clean_shutdown
    # - VM.checkpoint
    # - VM.clean_reboot
    # - VM.clean_shutdown
    # - VM.clone
    # - VM.copy
    # - VM.hard_reboot
    # - VM.hard_shutdown
    # - VM.pause
    # - VM.pool_migrate
    # - VM.provision
    # - VM.resume
    # - VM.resume_on
    # - VM.revert
    # - VM.send_sysrq
    # - VM.send_trigger
    # - VM.snapshot
    # - VM.snapshot_with_quiesce
    # - VM.start
    # - VM.start_on
    # - VM.suspend
    # - VM.unpause
    class VMBadPowerState < GenericError; end

    # An error occured while restoring the memory image of the
    # specified virtual machine
    #
    # Raised by
    # - VM.checkpoint
    class VMCheckpointResumeFailed < GenericError; end

    # An error occured while saving the memory image of the
    # specified virtual machine
    #
    # Raised by
    # - VM.checkpoint
    class VMCheckpointSuspendFailed < GenericError; end

    # HVM is required for this operation
    #
    # Raised by
    # - VM.start
    class VMHvmRequired < GenericError; end

    # The operation attempted is not valid for a template VM
    #
    # Raised by
    # - VM.clean_reboot
    # - VM.clean_shutdown
    # - VM.hard_reboot
    # - VM.hard_shutdown
    # - VM.pause
    # - VM.pool_migrate
    # - VM.resume
    # - VM.resume_on
    # - VM.start
    # - VM.start_on
    # - VM.suspend
    # - VM.unpause
    class VMIsTemplate < GenericError; end

    # An error occurred during the migration process.
    #
    # Raised by
    # - VM.pool_migrate
    class VMMigrateFailed < GenericError; end

    # You attempted an operation on a VM which requires PV drivers
    # to be installed but the drivers were not detected.
    #
    # Raised by
    # -VM.pool_migrate
    class VMMissingPVDrivers < GenericError; end

    # You attempted to run a VM on a host which doesn't have access to an SR
    # needed by the VM. The VM has at least one VBD attached to a VDI in the SR
    #
    # Raised by
    # - VM.assert_can_boot_here
    class VMRequiresSR < GenericError; end

    # An error occured while reverting the specified virtual machine
    # to the specified snapshot
    #
    # Raised by
    # - VM.revert
    class VMRevertFailed < GenericError; end

    # The quiesced-snapshot operation failed for an unexpected reason
    #
    # Raised by
    # - VM.snapshot_with_quiesce
    class VMSnapshotWithQuiesceFailed < GenericError; end

    # The VSS plug-in is not installed on this virtual machine
    #
    # Raised by
    # - VM.snapshot_with_quiesce
    class VMSnapshotWithQuiesceNotSupported < GenericError; end

    # The VSS plug-in cannot be contacted
    #
    # Raised by
    # - VM.snapshot_with_quiesce
    class VMSnapshotWithQuiescePluginDoesNotRespond < GenericError; end

    # The VSS plug-in has timed out
    #
    # Raised by
    # - VM.snapshot_with_quiesce
    class VMSnapshotWithQuiesceTimeout < GenericError; end

    # Returns the class for the exception appropriate for the error description given
    #
    # @param [String] desc ErrorDescription value from the API
    # @return [Class] Appropriate exception class for the given description
    def self.exception_class_from_desc(desc)
      case desc
      when 'BOOTLOADER_FAILED'
        BootloaderFailed
      when 'DEVICE_ALREADY_DETACHED'
        DeviceAlreadyDetached
      when 'DEVICE_DETACH_REJECTED'
        DeviceDetachRejected
      when 'EVENTS_LOST'
        EventsLost
      when 'HA_OPERATION_WOULD_BREAK_FAILOVER_PLAN'
        HAOperationWouldBreakFailoverPlan
      when 'HOST_IS_SLAVE'
        HostIsSlave
      when 'HOST_NAME_INVALID'
        HostNameInvalid
      when 'HOST_NOT_ENOUGH_FREE_MEMORY'
        HostNotEnoughFreeMemory
      when 'IS_TUNNEL_ACCESS_PIF'
        IsTunnelAccessPIF
      when 'JOINING_HOST_CANNOT_CONTAIN_SHARED_SRS'
        JoiningHostCannotContainSharedSRs
      when 'LICENCE_RESTRICTION'
        LicenceRestriction
      when 'LICENSE_PROCESSING_ERROR'
        LicenseProcessingError
      when 'NO_HOSTS_AVAILABLE'
        NoHostsAvailable
      when 'OPENVSWITCH_NOT_ACTIVE'
        OpenvswitchNotActive
      when 'OPERATION_NOT_ALLOWED'
        OperationNotAllowed
      when 'OTHER_OPERATION_IN_PROGRESS'
        OtherOperationInProgress
      when 'PIF_IS_PHYSICAL'
        PIFIsPhysical
      when 'PIF_TUNNEL_STILL_EXISTS'
        PIFTunnelStillExists
      when 'SESSION_AUTHENTICATION_FAILED'
        SessionAuthenticationFailed
      when 'SESSION_NOT_REGISTERED'
        SessionNotRegistered
      when 'SR_FULL'
        SRFull
      when 'SR_HAS_PDB'
        SRHasPDB
      when 'SR_OPERATION_NOT_SUPPORTED'
        SROperationNotSupported
      when 'SR_UNKNOWN_DRIVER'
        SRUnknownDriver
      when 'TRANSPORT_PIF_NOT_CONFIGURED'
        TransportPIFNotConfigured
      when 'UNKNOWN_BOOTLOADER'
        UnknownBootloader
      when 'VBD_IS_EMPTY'
        VBDIsEmpty
      when 'VBD_NOT_EMPTY'
        VBDNotEmpty
      when 'VBD_NOT_REMOVABLE_MEDIA'
        VBDNotRemovableMedia
      when 'VLAN_TAG_INVALID'
        VlanTagInvalid
      when 'VM_BAD_POWER_STATE'
        VMBadPowerState
      when 'VM_CHECKPOINT_RESUME_FAILED'
        VMCheckpointResumeFailed
      when 'VM_CHECKPOINT_SUSPEND_FAILED'
        VMCheckpointSuspendFailed
      when 'VM_HVM_REQUIRED'
        VMHVMRequired
      when 'VM_IS_TEMPLATE'
        VMIsTemplate
      when 'VM_MIGRATE_FAILED'
        VMMigrateFailed
      when 'VM_MISSING_PV_DRIVERS'
        VMMissingPVDrivers
      when 'VM_REQUIRES_SR'
        VMRequiresSR
      when 'VM_REVERT_FAILED'
        VMRevertFailed
      when 'VM_SNAPSHOT_WITH_QUIESCE_FAILED'
        VMSnapshotWithQuiesceFailed
      when 'VM_SNAPSHOT_WITH_QUIESCE_NOT_SUPPORTED'
        VMSnapshotWithQuiesceNotSupported
      when 'VM_SNAPSHOT_WITH_QUIESCE_PLUGIN_DOES_NOT_RESPOND'
        VMSnapshotWithQuiescePluginDoesNotRespond
      when 'VM_SNAPSHOT_WITH_QUIESCE_TIMEOUT'
        VMSnapshotWithQuiesceTimeout
      else
        GenericError
      end
    end
  end
end
