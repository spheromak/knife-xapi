require 'uri'
require 'xmlrpc/client'

module XenApi #:nodoc:
  # This class permits the invocation of XMLRPC API calls
  # through a ruby-like interface
  #
  #   client = XenApi::Client.new('http://xenapi.test')
  #   client.login_with_password('root', 'password')
  #   client.VM.get_all
  #
  # == Authenticating with the API
  # Authentication with the API takes place through the API
  # +session+ class, usually using the +login_with_password+
  # method. The +Client+ handles this method specially to
  # enable it to retain the session identifier to pass to
  # invoked methods and perform reauthentication should the
  # session become stale.
  #
  #   client = XenApi::Client.new('http://xenapi.test')
  #   client.login_with_password('root', 'password')
  #
  # It is worth noting that only +login*+ matching methods
  # are specially passed through to the +session+ class.
  #
  # == Running code after API login
  # The +Client+ provides the ability for running code
  # after the client has successfully authenticated with
  # the API. This is useful for either logging authentication
  # or for registering for certain information from the API.
  #
  # The best example of this is when needing to make use of
  # the Xen API +event+ class for asynchronous event handling.
  # To use the API +event+ class you first have to register
  # your interest in a specific set of event types.
  #
  #   client = XenApi::Client.new('http://xenapi.test')
  #   client.after_login do |c|
  #     c.event.register %w(vm) # register for 'vm' events
  #   end
  #
  # == Asynchronous Methods
  # To call asynchronous methods on the Xen XMLRPC API you
  # first call +Async+ on the +Client+ instance followed by
  # the normal method name.
  # For example:
  #
  #   client = XenApi::Client.new('http://xenapi.test')
  #   client.login_with_password('root', 'password')
  #
  #   vm_ref = client.VM.get_by_name_label('my vm')
  #   task = client.Async.VM.clone(vm_ref)
  #   while client.Task.get_status(task) == "pending":
  #        progress = client.Task.get_progress(task)
  #        update_progress_bar(progress)
  #        time.sleep(1)
  #   client.Task.destroy(task)
  #
  # Calling either +Async+ or +async+ will work as the
  # capitalised form will always be sent when calling
  # a method asynchronously.
  #
  # Note that only some methods are available in an asynchronous variant.
  # An XMLRPC::FaultException is thrown if you try to call a method
  # asynchrounously that is not available.
  class Client
    # The +LoginRequired+ exception is raised when
    # an API request requires login and no login
    # credentials have yet been provided.
    #
    # If you don't perform a login before receiving this
    # exception then you will want to catch it, log into
    # the API and then retry your request.
    class LoginRequired < RuntimeError; end

    # The +SessionInvalid+ exception is raised when the
    # API session has become stale or is otherwise invalid.
    #
    # Internally this exception will be handled a number of
    # times before being raised up to the calling code.
    class SessionInvalid < RuntimeError; end

    # The +ResponseMissingStatusField+ exception is raised
    # when the XMLRPC response is missing the +Status+ field.
    # This typically indicates an unrecoverable error with
    # the API itself.
    class ResponseMissingStatusField < RuntimeError; end

    # The +ResponseMissingValueField+ exception is raised
    # when the XMLRPC response is missing the +Value+ field.
    # This typically indicates an unrecoverable error with
    # the API itself.
    class ResponseMissingValueField < RuntimeError; end

    # The +ResponseMissingErrorDescriptionField+ exception
    # is raised when an error is returned in the XMLRPC
    # response, but the type of error cannot be determined
    # due to the lack of the +ErrorDescription+ field.
    class ResponseMissingErrorDescriptionField < RuntimeError; end

    # @see Object#inspect
    def inspect
      "#<#{self.class} #{@uri}>"
    end

    # @param [String,Array] uri URL to the Xen API endpoint
    # @param [Integer] timeout Maximum number of seconds to wait for an API response
    # @param [Symbol] ssl_verify SSL certificate verification mode.
    #   Can be one of :verify_none or :verify_peer
    def initialize(uris, timeout=10, ssl_verify=:verify_peer)
      @timeout = timeout
      @ssl_verify = ssl_verify
      @uris = [uris].flatten.collect do |uri|
        uri = URI.parse(uri)
        uri.path = '/' if uri.path == ''
        uri
      end.uniq
      @uri = @uris.first
    end

    attr_reader :uri, :uris

    # @overload after_login
    #   Adds a block to be called after successful login to the XenAPI.
    #   @note The block will be called whenever the receiver has to authenticate
    #     with the XenAPI. This includes the first time the receiver recieves a
    #     +login_*+ method call and any time the session becomes invalid.
    #   @yield client
    #   @yieldparam [optional, Client] client Client instance
    # @overload after_login
    #   Calls the created block, this is primarily for internal use only
    # @return [Client] receiver
    def after_login(&block)
      if block
        @after_login = block
      elsif @after_login
        case @after_login.arity
        when 1
          @after_login.call(self)
        else
          @after_login.call
        end
      end
      self
    end

    # @overload before_reconnect
    #   Adds a block to be called before an attempted reconnect to another server.
    #   @note The block will be called whenever the receiver has to chose a
    #     new server because the current connection got invalid.
    #   @yield client
    #   @yieldparam [optional, Client] client Client instance
    # @overload before_reconnect
    #   Calls the created block, this is primarily for internal use only
    # @return [Client] receiver
    def before_reconnect(&block)
      if block
        @before_reconnect = block
      elsif @before_reconnect
        case @before_reconnect.arity
        when 1
          @before_reconnect.call(self)
        else
          @before_reconnect.call
        end
      end
      self
    end

    # Returns the current session identifier.
    #
    # @return [String] session identifier
    def xenapi_session
      @session
    end

    # Returns the current API version
    #
    # @return [String] API version
    def api_version
      @api_version ||= begin
        pool = self.pool.get_all()[0]
        host = self.pool.get_master(pool)
        major = self.host.get_API_version_major(host)
        minor = self.host.get_API_version_minor(host)
        "#{major}.#{minor}"
      end
    end

    # Handle API method calls.
    #
    # If the method called starts with +login+ then the method is
    # assumed to be part of the +session+ namespace and will be
    # called directly. For example +login_with_password+
    #
    #   client = XenApi::Client.new('http://xenapi.test/')
    #   client.login_with_password('root', 'password)
    #
    # If the method called is +async+ then an +AsyncDispatcher+
    # will be created to handle the asynchronous API method call.
    #
    #   client = XenApi::Client.new('http://xenapi.test/')
    #   client.async.host.get_servertime(ref)
    #
    # The final case will create a +Dispatcher+ to handle the
    # subsequent method call such as.
    #
    #   client = XenApi::Client.new('http://xenapi.test/')
    #   client.host.get_servertime(ref)
    #
    # @note +meth+ names are not validated
    #
    # @param [String,Symbol] meth Method name
    # @param [...] args Method args
    # @return [true,AsyncDispatcher,Dispatcher]
    def method_missing(meth, *args)
      case meth.to_s
      when /^(slave_local_)?login/
        _login(meth, *args)
      when /^async/i
        AsyncDispatcher.new(self, :_call)
      else
        Dispatcher.new(self, meth, :_call)
      end
    end

    # Logout and destroy the current session. After calling logout, the
    # object state is invalid. No API calls can be performed unless one of
    # the login methods is called again.
    def logout
      begin
        if @login_meth.to_s.start_with? "slave_local"
          _do_call("session.local_logout", [@session])
        else
          _do_call("session.logout", [@session])
        end
      rescue
        # We don't care about any error. If it works: great, if not: shit happens...
        nil
      ensure
        @session = ""
        @login_meth = nil
        @login_args = []
        @api_version = nil
      end
    end

  protected
    # @param [String,Symbol] meth API method to call
    # @param [Array] args Arguments to pass to the method call
    # @raise [SessionInvalid] Reauthentication failed
    # @raise [LoginRequired] Authentication required, unable to login automatically
    # @raise [EOFError] XMLRPC::Client exception
    # @raise [Errno::EPIPE] XMLRPC::Client exception
    def _call(meth, *args)
      begin
        _do_call(meth, args.dup.unshift(@session))
      rescue SessionInvalid
        _relogin_attempts = (_relogin_attempts || 0) + 1
        _relogin
        retry unless _relogin_attempts > 2
        _reconnect ? retry : raise
      rescue Timeout::Error
        _timeout_retries = (_timeout_retries || 0) + 1
        @client = nil
        retry unless _timeout_retries > 1
        _reconnect ? retry : raise
      rescue EOFError
        _eof_retries = (_eof_retries || 0) + 1
        @client = nil
        retry unless _eof_retries > 1
        _reconnect ? retry : raise
      rescue Errno::EPIPE
        _epipe_retries = (_epipe_retries || 0) + 1
        @client = nil
        retry unless _epipe_retries > 1
        _reconnect ? retry : raise
      rescue Errno::EHOSTUNREACH
        @client = nil
        _reconnect ? retry : raise
      end
    end

  private
    # Reauthenticate with the API
    # @raise [LoginRequired] Missing authentication credentials
    def _relogin
      raise LoginRequired if @login_meth.nil? || @login_args.nil? || @login_args.empty?
      _login(@login_meth, *@login_args)
    end

    # Try to reconnect to another available server in the same pool
    #
    # @note Will call the +before_reconnect+ block before trying to reconnect
    #
    # @raise [Errors::NoHostsAvailable] No further hosts available to connect to
    # @raise [LoginRequired] Missing authentication credentials
    def _reconnect
      return false if @i_am_reconnecting

      @i_am_reconnecting = true
      failed_uris = [@uri]
      while (available_uris = (@uris - failed_uris)).count > 0
        @uri = available_uris[0]
        @client = nil

        begin
          before_reconnect
          _relogin
          @i_am_reconnecting = false
          return true
        rescue LoginRequired
          raise
        rescue
          failed_uris << @uri
        end
      end
      raise Errors::NoHostsAvailable.new("No server reachable. Giving up.")
    end

    # Login to the API
    #
    # @note Will call the +after_login+ block if login is successful
    #
    # @param [String,Symbol] meth Login method name
    # @param [...] args Arguments to pass to the login method
    # @return [Boolean] true
    # @raise [Exception] any exception raised by +_do_call+ or +after_login+
    def _login(meth, *args)
      begin
        @session = _do_call("session.#{meth}", args)
      rescue Errors::HostIsSlave => e
        @uri = @uri.dup
        @uri.host = e.description[0]
        @uris.unshift(@uri).uniq!
        @client = nil
        retry
      end

      @login_meth = meth
      @login_args = args
      after_login
      true
    end

    # Return or initialize new +XMLRPC::Client+
    #
    # @return [XMLRPC::Client] XMLRPC client instance
    def _client
      @client ||= XMLRPCClient.new(@uri.host, @uri.path, @uri.port, nil, nil, nil, nil, @uri.scheme == "https" ? @ssl_verify : false, @timeout)
    end

    # Perform XMLRPC method call.
    #
    # @param [String,Symbol] meth XMLRPC method to call
    # @param [Array] args XMLRPC method arguments
    # @param [Integer] attempts Number of times to retry the call, presently unused
    # @return [Object] method return value
    # @raise [ResponseMissingStatusField] XMLRPC response does not have a +Status+ field
    # @raise [ResponseMissingValueField] XMLRPC response does not have a +Value+ field
    # @raise [ResponseMissingErrorDescriptionField] API response error missing +ErrorDescription+ field
    # @raise [SessionInvalid] API session has expired
    # @raise [Errors::GenericError] API method specific error
    def _do_call(meth, args, attempts = 3)
      r = _client.call(meth, *args)
      raise ResponseMissingStatusField unless r.has_key?('Status')

      if r['Status'] == 'Success'
        return r['Value'] if r.has_key?('Value')
        raise ResponseMissingValueField
      else
        raise ResponseMissingErrorDescriptionField unless r.has_key?('ErrorDescription')
        raise SessionInvalid if r['ErrorDescription'][0] == 'SESSION_INVALID'

        ed = r['ErrorDescription'].shift
        ex = Errors.exception_class_from_desc(ed)
        r['ErrorDescription'].unshift(ed) if ex == Errors::GenericError
        raise ex, r['ErrorDescription']
      end
    end
  end
end
