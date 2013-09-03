require 'minitest/unit'
require 'minitest/autorun'
$:<< File.dirname(__FILE__) + "/../lib"
require 'localjob'
require "mocha/setup"
require 'jobs'

class LocaljobTestCase < MiniTest::Unit::TestCase
  protected
  # This is a method to make sure the logger is set right.
  def worker(queues = ["/localjob-test"])
    Localjob::Worker.new(queues, logger: logger)
  end

  # This is a method to make sure all queues are registred and destroyed after
  # each teach run.
  def queue(name = "/localjob-test")
    @queues ||= []
    queue = Localjob.new(name)
    @queues << queue
    queue
  end

  def teardown
    clear_queue
  end

  def logger
    return @logger if @logger

    output_file = ENV["DEBUG"] ? STDOUT : "/dev/null"
    @logger = Logger.new(output_file)
  end

  def clear_queue
    @queues.each(&:destroy) if @queues

    # This forces the GC to garbage collect, and thus close file descriptioners
    # in POSIX::Mqueue. Otherwise we'll get flooded with warnings. This is to
    # ensure a clean state everytime with a new message queue for each test.
    # It's slower. But safe.
    GC.start
  end
end
