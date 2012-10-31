module XenApi
  autoload :Client,           File.expand_path('../xenapi/client',            __FILE__)
  autoload :Errors,           File.expand_path('../xenapi/errors',            __FILE__)
  autoload :Dispatcher,       File.expand_path('../xenapi/dispatcher',        __FILE__)
  autoload :AsyncDispatcher,  File.expand_path('../xenapi/async_dispatcher',  __FILE__)
  autoload :XMLRPCClient,     File.expand_path('../xenapi/xmlrpc_client',     __FILE__)

  # Perform some action in a session context
  #
  # @param [String,Array] hosts
  #   Host or hosts to try to connect to. Pass multiple URLs to allow to find
  #   the pool master even if the originally designated host is not reachable.
  # @param [String] username Username used for login
  # @param [String] password Password used for login
  # @param [Hash(Symbol => Boolean, String)] options
  #   Additional options:
  #     +:api_version+:: Force the usage of this API version if true
  #     +:slave_login+:: Authenticate locally against a slave in emergency mode if true.
  #     +:keep_session+:: Don't logout afterwards to keep the session usable if true
  #     +:timeout+:: Maximum number of seconds to wait for an API response
  #     +:ssl_verify+:: SSL certificate verification mode. Can be one of :verify_none or :verify_peer
  # @yield client
  # @yieldparam [Client] client Client instance
  # @return [Object] block return value
  # @raise [NoHostsAvailable] No hosts could be contacted
  def self.connect(uris, username, password, options={})
    uris = uris.respond_to?(:shift) ? uris.dup : [uris]
    method = options[:slave_login] ? :slave_local_login_with_password : :login_with_password

    client = Client.new(uris, options[:timeout] || 10, options[:ssl_verify] || :verify_peer)
    begin
      args = [method, username, password]
      args << options[:api_version] if options.has_key?(:api_version)
      client.send(*args)

      if block_given?
        return yield client
      else
        options[:keep_session] = true
        return client
      end
    ensure
      client.logout unless options[:keep_session] || client.xenapi_session.nil?
    end
  end
end

