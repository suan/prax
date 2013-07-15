$:.unshift File.expand_path("../../lib", File.realpath(__FILE__))

ENV['PRAX_HTTP_PORT']  = '20557'
ENV['PRAX_HTTPS_PORT'] = '20556'

require 'minitest/spec'
require 'minitest/colorize'
require 'minitest/autorun'
require 'prax/server'

Thread.abort_on_exception = true

$mutex = Mutex.new
$started, $stopped = ConditionVariable.new, ConditionVariable.new

module Prax
  class Worker
    def started; Prax.started; end
    def stopped; Prax.stopped; end
  end

  class Server
    def started; Prax.started; end
    def stopped; Prax.stopped; end
  end

  def self.worker; @worker; end
  def self.server; @server; end

  def self.started
    $mutex.synchronize {
      @i ||= 0; @i += 1
      $started.signal if @i == 2
    }
  end

  def self.stopped
    $mutex.synchronize {
      @i ||= 0; @i -= 1
      $stopped.signal if @i == 0
    }
  end
end

class GenericServerTest < Prax::Generic::Server
  def serve(socket, ssl)
    case socket.gets
    when "PENDING\r\n"
      sleep 0.2
    when "IMMEDIATE\r\n"
    end

    socket.write "OK"
    socket.close
  end

  def started; $mutex.synchronize { $started.signal }; end
  def stopped; $mutex.synchronize { $stopped.signal }; end

  def ssl_crt; File.expand_path('../ssl/server.crt', __FILE__); end
  def ssl_key; File.expand_path('../ssl/server.key', __FILE__); end
end

class GenericWorkerTest < Prax::Generic::Worker
  attr_reader :threads

  def perform
    loop {
      raise StandardError.new if @faulty
      break if @_stopping
    }
  end

  def error(detail); end
  def started; $mutex.synchronize { $started.signal }; end
  def stopped; $mutex.synchronize { $stopped.signal }; end
end

class Minitest::Spec
  def client(type, hostname, port = nil, &block)
    case type
    when :tcp  then tcp_client(hostname,  port, &block)
    when :ssl  then ssl_client(hostname,  port, &block)
    when :unix then unix_client(hostname, &block)
    end
  end

  def tcp_client(hostname, port)
    socket = TCPSocket.new(hostname, port)
    yield socket if block_given?
  ensure
    socket.close if socket
  end

  def unix_client(path)
    socket = UNIXSocket.new(path)
    yield socket if block_given?
  ensure
    socket.close if socket
  end

  def ssl_client(hostname, port)
    tcp_client(hostname, port) do |tcp|
      socket = OpenSSL::SSL::SSLSocket.new(tcp, ssl_context)
      socket.sync_close = true
      socket.connect
      yield socket if block_given?
    end
  end

  def ssl_context
    @ssl_context ||= begin
      ctx      = OpenSSL::SSL::SSLContext.new
      path     = File.expand_path('../ssl', __FILE__)
      ctx.cert = OpenSSL::X509::Certificate.new(File.read(File.join(path, 'client.crt')))
      ctx.key  = OpenSSL::PKey::RSA.new(File.read(File.join(path, 'client.key')))
      ctx
    end
  end
end
