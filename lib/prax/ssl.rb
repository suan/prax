require 'openssl'

module Prax
  module SSL
    def ssl_configured?
      ssl_crt and File.exists?(ssl_crt) and ssl_key and File.exists?(ssl_key)
    end

    def ssl_server(*args)
      ctx      = OpenSSL::SSL::SSLContext.new
      ctx.cert = OpenSSL::X509::Certificate.new(File.read(ssl_crt))
      ctx.key  = OpenSSL::PKey::RSA.new(File.read(ssl_key))
      OpenSSL::SSL::SSLServer.new(TCPServer.new(*args), ctx)
    end

    def ssl_crt
    end

    def ssl_key
    end
  end
end
