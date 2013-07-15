require 'test_helper'
require 'prax/server'

describe Prax do
  before do
    Thread.new { Prax.run }
    $mutex.synchronize { $started.wait($mutex) }
  end

  describe "run" do
    after do
      Prax.stop
      $mutex.synchronize { $stopped.wait($mutex) }
    end

    it "must start workers" do
      assert Prax.worker.started?
    end

    it "must start servers" do
      assert Prax.server.started?
    end

    it "must start TCP server" do
      tcp_client('localhost', Prax::Config.http_port) do |socket|
        socket.write("GET / HTTP/1.1\r\nHost: test.dev\r\n\r\n")
      end
      sleep 0.001 # FIXME: get rid of that sleep!
    end

    it "must start SSL server" do
      ssl_client('localhost', Prax::Config.https_port) do |socket|
        socket.write("GET / HTTP/1.1\r\nHost: test.dev\r\n\r\n")
      end
      sleep 0.001 # FIXME: get rid of that sleep!
    end
  end

  #describe "shutdown" do
  #  before do
  #    Prax.stop
  #    $mutex.synchronize { $stopped.wait($mutex) }
  #  end

  #  it "must stop worker" do
  #    assert Prax.worker.stopped?
  #  end

  #  it "must stop server" do
  #    refute Prax.server.started?
  #  end

  #  it "must stop TCP server" do
  #    assert_raises(Errno::ECONNREFUSED) do
  #      tcp_client('localhost', Prax::Config.http_port)
  #    end
  #  end

  #  it "must stop SSL server" do
  #    assert_raises(Errno::ECONNREFUSED) do
  #      ssl_client('localhost', Prax::Config.http_port)
  #    end
  #  end
  #end
end

