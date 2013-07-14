require 'thread'

module Prax
  module Generic
    class Worker
      DEFAULT_SIZE = 16

      attr_accessor :size, :logger

      def self.run(*args)
        worker = new(*args)
        worker.start
        worker
      end

      def initialize(size = DEFAULT_SIZE)
        @mutex = Mutex.new
        @size = size
      end

      def start
        return if started?
        @mutex.synchronize { @threads = size.times.map { spawn } }
        started
      end

      def stop
        @_stopping = true
        stopped
      end

      def perform; end
      def started; end
      def stopped; end

      # IMPROVE: Prax::Generic::Worker#error(detail)
      def error(detail)
        puts "\n" + detail.to_s + ":\n" + detail.backtrace.join("\n")
      end

      def started?
        @threads and @threads.any?
      end

      def stopped?
        @_stopping or @threads.nil? or @threads.empty?
      end

      private
        def spawn
          Thread.new do
            begin
              perform
            rescue => detail
              error(detail)
            ensure
              @mutex.synchronize do
                @threads.delete(Thread.current)
                respawn unless @_stopping
              end
            end
          end
        end
    end
  end
end
