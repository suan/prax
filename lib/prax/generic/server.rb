require 'socket'
require 'prax/ssl'

module Prax
  module Generic
    class Server
      include Prax::SSL

      attr_accessor :config, :servers

      # Example:
      #   @server = Server.new [3000], [:ssl, 3001], [:unix, '/tmp/myapp.sock']
      #   @server.start.run
      def initialize(*config)
        @mutex = Mutex.new
        @pipe  = IO.pipe

        self.config  = []
        self.servers = []

        config.each { |conf| add(*conf) }
      end

      # Examples:
      #   server.add(3000)
      #   server.add('hostname', 3000)
      #   server.add(:ssl, 3001)
      #   server.add(:ssl, '10.0.0.5', 3001)
      #   server.add(:unix, '/tmp/app.sock')
      def add(type, host = nil, port = nil)
        self.config << if type.is_a?(Symbol)
                         { type: type, args: [host, port].compact }
                       else
                         { type: :tcp, args: [type, host].compact }
                       end
      end

      def serve(socket, ssl)
      end

      def run
        start

        loop do
          begin
            IO.select(self.servers + [@pipe.first]).first.each do |stream|
              if stream == @pipe.first
                finalize
              else
                ssl = stream.is_a?(OpenSSL::SSL::SSLServer)
                serve(stream.accept, ssl)
              end
            end
            break if @stopping or servers.nil?
          rescue OpenSSL::SSL::SSLError
          end
        end
      end

      def start
        @mutex.synchronize do
          return if started?
          @stopping = false
          start_servers
        end

        started
        self
      end

      def stop
        @stopping = true
        @pipe.last.write_nonblock('.')
      end

      def finalize
        @pipe.first.read_nonblock(1)
        close_servers!
        clean_sockets!
        stopped
      end

      def started?
        servers and servers.any?
      end

      def stopping?
        @stopping
      end

      # Called when the servers have been started.
      def started
      end

      # Called when the servers have stopped.
      def stopped
      end

      private
        def start_servers
          self.servers = config.map do |conf|
            case conf[:type]
            when :ssl  then ssl_server(*conf[:args])
            when :tcp  then TCPServer.new(*conf[:args])
            when :unix then UNIXServer.new(*conf[:args])
            end
          end
        end

        def close_servers!
          servers.each do |server, i|
            begin
              server.close
            rescue
            end
          end
          self.servers = nil
        end

        def clean_sockets!
          config.each do |conf|
            if conf[:type] == :unix
              socket_path = conf[:args].first
              File.unlink(socket_path) if File.exists?(socket_path)
            end
          end
        end
    end
  end
end
