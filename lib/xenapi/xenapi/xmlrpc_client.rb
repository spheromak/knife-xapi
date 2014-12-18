module XenApi
  class XMLRPCClient < ::XMLRPC::Client
    def initialize(host = nil, path = nil, port = nil, proxy_host = nil, proxy_port = nil,
                   user = nil, password = nil, use_ssl = nil, timeout = nil)

      if use_ssl == :verify_none
        use_ssl = :verify_none
      elsif !!use_ssl
        use_ssl = :verify_peer
      end

      super(host, path, port, proxy_host, proxy_port, user, password, !!use_ssl, timeout)

      case use_ssl
      when :verify_peer
        store = OpenSSL::X509::Store.new
        store.set_default_paths
        @http.cert_store = store
        @http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      when :verify_none
        warn "warning: peer certificate won't be verified in this SSL session"
        @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
    end
  end
end
