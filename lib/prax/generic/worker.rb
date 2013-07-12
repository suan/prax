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
        @mutex.synchronize do
          @threads = size.times.map { spawn }
        end
      end

      def stop
        @stop = true
      end

      def perform
      end

      # TODO: Prax::Generic::Worker#error(detail)
      def error(detail)
      end

      private
        def spawn
          Thread.new do
            begin
              perform
            rescue => detail
              error(detail)
              respawn unless @stop
              raise
            end
          end
        end

        def respawn
          @mutex.synchronize do
            threads.delete(Thread.current)
            threads << spawn if threads.size < size
          end
        end
    end
  end
end
