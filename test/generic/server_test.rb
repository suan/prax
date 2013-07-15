require 'test_helper'
require 'prax/generic/server'

describe Prax::Generic::Server do
  before do
    @spawned = []
    @socket_path = '/tmp/test_generic_server.sock'
  end

  after do
    @spawned.each do |thread, server|
      $mutex.synchronize { server.stop; $stopped.wait($mutex) } if server.started?
      thread.join
    end
    File.unlink(@socket_path) if File.exists?(@socket_path)
  end

  describe "initialize" do
    before { @server = Prax::Generic::Server.new }

    it("must have empty config")  { assert @server.config.empty? }
    it("must have empty servers") { assert @server.servers.empty? }

    it "must set config" do
      @server = Prax::Generic::Server.new([20559], [:ssl, 20558])
      assert_equal [
        { type: :tcp, args: [20559] },
        { type: :ssl, args: [20558] },
      ], @server.config
    end
  end

  describe "add" do
    before { @server = Prax::Generic::Server.new }

    it "tcp: port" do
      @server.add 12345
      assert_equal({ type: :tcp, args: [12345] }, @server.config.last)
    end

    it "tcp: host + port" do
      @server.add 'localhost', 12345
      assert_equal({ type: :tcp, args: ['localhost', 12345] }, @server.config.first)
    end

    it "ssl: port" do
      @server.add :ssl, 12345
      assert_equal({ type: :ssl, args: [12345] }, @server.config.first)
    end

    it "ssl: host + port" do
      @server.add :ssl, 'localhost', 12345
      assert_equal({ type: :ssl, args: ['localhost', 12345] }, @server.config.first)
    end

    it "unix: socket" do
      @server.add :unix, '/tmp/app.sock'
      assert_equal({ type: :unix, args: ['/tmp/app.sock'] }, @server.config.first)
    end

    it "must add many conf" do
      @server.add :ssl, '10.0.0.5', 54321
      @server.add :tcp, 12345
      @server.add :tcp, '::1', 12345
      @server.add :unix, '/tmp/appname.sock'

      assert_equal [
        { type: :ssl,  args: ['10.0.0.5', 54321] },
        { type: :tcp,  args: [12345] },
        { type: :tcp,  args: ['::1', 12345] },
        { type: :unix, args: ['/tmp/appname.sock'] },
      ], @server.config
    end
  end

  describe "start" do
    it "must start a TCP server" do
      @server = spawn([12345])
      client(:tcp, 'localhost', 12345, &immediate)
    end

    it "must start a SSL server" do
      @server = spawn([:ssl, 12346])
      client(:ssl, 'localhost', 12346, &immediate)
    end

    it "must start an UNIX server" do
      @server = spawn([:unix, @socket_path])
      client(:unix, @socket_path, &immediate)
      assert File.exists?(@socket_path)
    end

    it "must start a TCP, UNIX and SSL servers" do
      @server = spawn([12347], [:unix, @socket_path], [:ssl, 54322])
      client(:tcp,  'localhost', 12347, &immediate)
      client(:ssl,  'localhost', 54322, &immediate)
      client(:unix, @socket_path, &immediate)
    end
  end

  describe "stop" do
    before do
      @server = spawn([12350], [:ssl, 50321], [:unix, @socket_path])
    end

    it "must stop all the servers" do
      $mutex.synchronize {
        @server.stop
        $stopped.wait($mutex)
      }
      assert_raises(Errno::ECONNREFUSED) { client(:tcp, 'localhost', 12350) }
      assert_raises(Errno::ECONNREFUSED) { client(:ssl, 'localhost', 50321) }
      assert_raises(Errno::ENOENT)       { client(:unix, @socket_path) }
    end

    it "must remove the unix sockets" do
      $mutex.synchronize {
        @server.stop
        $stopped.wait($mutex)
      }
      refute File.exists?(@socket_path)
    end
  end

  let(:immediate) do
    proc { |socket| socket.write("IMMEDIATE\r\n"); assert_equal 'OK', socket.gets }
  end

  let(:pending) do
    proc { |socket| socket.write("PENDING\r\n"); assert_equal 'OK', socket.gets }
  end

  protected
    def client(type, hostname, port = nil, &block)
      case type
      when :tcp  then tcp_client(hostname,  port, &block)
      when :ssl  then ssl_client(hostname,  port, &block)
      when :unix then unix_client(hostname, &block)
      end
    end

    def tcp_client(hostname, port)
      socket = TCPSocket.new(hostname, port)
      yield socket
    ensure
      socket.close if socket
    end

    def unix_client(path)
      socket = UNIXSocket.new(path)
      yield socket
    ensure
      socket.close if socket
    end

    def ssl_client(hostname, port)
      tcp_client(hostname, port) do |tcp|
        socket = OpenSSL::SSL::SSLSocket.new(tcp, ssl_context)
        socket.sync_close = true
        socket.connect
        yield socket
      end
    end

    def ssl_context
      @ssl_context ||= begin
        ctx      = OpenSSL::SSL::SSLContext.new
        path     = File.expand_path('../../ssl', __FILE__)
        ctx.cert = OpenSSL::X509::Certificate.new(File.read(File.join(path, 'client.crt')))
        ctx.key  = OpenSSL::PKey::RSA.new(File.read(File.join(path, 'client.key')))
        ctx
      end
    end

    def spawn(*args)
      server = GenericServerTest.new(*args)
      thread = Thread.new { server.run }
      $mutex.synchronize { $started.wait($mutex) }
      @spawned << [thread, server]
      server
    end
end
