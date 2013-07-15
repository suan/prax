require 'test_helper'
require 'prax/generic/worker'

describe Prax::Generic::Worker do
  after { worker.stop if worker.started? }

  let :worker do
    GenericWorkerTest.new(4)
  end

  describe "initialize" do
    it "must have default size" do
      worker = GenericWorkerTest.new
      assert_equal Prax::Generic::Worker::DEFAULT_SIZE, worker.size
    end

    it "must have size" do
      assert_equal 4, worker.size
    end
  end

  describe "start" do
    before { worker.start }

    it "must populate the pool of threads" do
      assert_equal 4, worker.threads.size
    end

    it "must be started" do
      assert worker.started?
      refute worker.stopped?
    end
  end

  describe "stop" do
    before do
      worker.start
      worker.stop
      $mutex.synchronize { $stopped.wait($mutex) }
    end

    it "must empty the pool of threads" do
      assert_equal 0, worker.threads.size
    end

    it "must be stopped" do
      assert worker.stopped?
      refute worker.started?
    end
  end

  describe "failure" do
    before do
      worker.start
      worker.instance_variable_set(:@faulty, true)
    end

    it "must clean any faulty thread" do
      worker.threads.each { |thr| assert thr.alive? }
    end

    it "must respawn the faulty thread" do
      assert_equal 4, worker.threads.size
    end
  end
end
