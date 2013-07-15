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

  def ssl_crt; File.expand_path('../../ssl/server.crt', __FILE__); end
  def ssl_key; File.expand_path('../../ssl/server.key', __FILE__); end
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

