$:.unshift File.expand_path("../../lib", File.realpath(__FILE__))

require 'minitest/spec'
require 'minitest/colorize'
require 'minitest/autorun'

Thread.abort_on_exception = true
$queue = Queue.new

