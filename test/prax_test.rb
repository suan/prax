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

    # it "must start TCP server"
    # it "must start SSL server"
  end

  describe "shutdown" do
    before do
      Prax.stop
      $mutex.synchronize { $stopped.wait($mutex) }
    end

    it "must stop worker" do
      assert Prax.worker.stopped?
    end

    it "must stop server" do
      refute Prax.server.started?
    end
  end
end

