module XenApi #:nodoc:
  # @private
  # This class helps to provide XMLRPC method dispatching.
  #
  # Calls made to the top level +XenApi::Client+ instance
  # will generate instances of this class to provide scoping
  # of methods by their prefix. All Xen API method calls are
  # two level, the first level specifies a namespace or prefix
  # for the second level method call. Taking +VM.start+ as
  # an example, +VM+ is the namespace prefix and +start+ is
  # the method name.
  #
  # Calling Xen API XMLRPC methods therefore consists of
  # first creating a +Dispatcher+ instance with the prefix
  # name and then calling a method on the +Dispatcher+
  # instance to create the XMLRPC method name to be called
  # by the +XenApi::Client+ instance.
  #
  #   client = XenApi::Client.new('http://xenapi.test/')
  #   client.VM             #=> Dispatcher instance for 'VM'
  #   client.VM.start()     #=> Performs XMLRPC 'VM.start' call
  class Dispatcher
    undef :clone  # to allow for VM.clone calls

    # @param [Client] client XenApi::Client instance
    # @param [String] prefix Method prefix name
    # @param [Symbol] sender XenApi::Client method to call when prefix method is invoked
    def initialize(client, prefix, sender)
      @client = client
      @prefix = prefix
      @sender = sender
    end

    # @see Object#inspect
    def inspect
      "#<#{self.class} #{@prefix}>"
    end

    # Calls a method on +XenApi::Client+ to perform the XMLRPC method
    #
    # @param [String,Symbol] meth Method name to be combined with the receivers +prefix+
    # @param [...] args Method arguments
    # @return [Object] XMLRPC response value
    def method_missing(meth, *args)
      @client.send(@sender, "#{@prefix}.#{meth}", *args)
    end
  end
end
