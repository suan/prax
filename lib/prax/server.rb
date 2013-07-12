require 'prax/config'
require 'prax/generic/worker'
require 'prax/generic/server'

Thread.abort_on_exception = Prax::Config.debug?

module Prax
  ROOT = File.expand_path('../../..', File.realpath(__FILE__))

  def self.queue
    @queue ||= Queue.new
  end

  class Handler
    def initialize(socket, ssl)
      # TODO
    end
  end

  class Worker < Generic::Worker
    def perform
      loop do
        socket, ssl = Prax.queue.pop
        Handler.new(socket, ssl)
      end
    end
  end

  class Server < Generic::Server
    def serve(socket, ssl)
      Prax.queue << [socket, ssl]
    end

    def ssl_crt
      File.join(ROOT, 'ssl', 'server.crt')
    end

    def ssl_key
      File.join(ROOT, 'ssl', 'server.key')
    end
  end

  def self.run
    @worker = Worker.run
    @server = Server.run [20559], [:ssl, 20558], [:unix, '/tmp/app.sock']
  end

  def self.shutdown
    @server.stop
    @worker.stop
    Process.kill 'TERM', -Process.getpgrp # Kill all children
  end
end
