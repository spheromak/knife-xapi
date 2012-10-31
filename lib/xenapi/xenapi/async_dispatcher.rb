module XenApi #:nodoc:
  # @private
  # This class helps to provide the ability for the +XenApi::Client+
  # to accept +async+ method calls. Calls are similar to synchronous
  # method calls except that the names are prefixed with 'Async'.
  #
  #   client = XenApi::Client.new('http://xenapi.test/')
  #   client.async            #=> AsyncDispatcher instance
  #   client.async.VM         #=> Dispatcher instance for 'Async.VM'
  #   client.async.VM.start() #=> Performs XMLRPC 'Async.VM.start' call
  #
  # further calls on instances of this object will create a +Dispatcher+
  # instance which then handle actual method calls.
  class AsyncDispatcher
    # @param [Client] client XenApi::Client instance
    # @param [Symbol] sender XenApi::Client method to call when prefix method is invoked
    def initialize(client, sender)
      @client = client
      @sender = sender
    end

    # @see Object#inspect
    def inspect
      "#<#{self.class}>"
    end

    # Create a new +Dispatcher+ instance to handle the +Async.meth+ prefix.
    #
    # @param [String,Symbol] meth Method prefix name
    # @param [...] args Method arguments
    # @return [Dispatcher] dispatcher instance to handle the +Async.meth+ prefix
    def method_missing(meth, *args)
      Dispatcher.new(@client, "Async.#{meth}", @sender)
    end
  end  
end
