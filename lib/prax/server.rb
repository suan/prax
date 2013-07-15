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

  # NOTE: shall we (still) make the SSL optional?
  def self.run
    @worker = Worker.run
    @server = Server.new [Config.http_port], [:ssl, Config.https_port]
    @server.run
  end

  def self.stop
    @server.stop
    @worker.stop
  end

  def self.shutdown
    stop
    Process.kill 'TERM', -Process.getpgrp # kill all processes in group
  end
end
