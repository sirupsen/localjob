require 'yaml'
require 'logger'
require 'forwardable'

require "localjob/version"
require 'localjob/channel'
require 'localjob/worker'

class Localjob
  extend Forwardable

  attr_reader :name
  attr_accessor :queue

  def_delegators :queue, :to_io, :destroy, :size

  def initialize(name = "localjob")
    @name = name
  end

  def serializer
    YAML
  end

  def queue
    return @queue if @queue

    case RUBY_PLATFORM
    when /linux/
      require 'localjob/linux_adapter'
      @queue = LinuxAdapter.new(@name)
    else
      require 'localjob/mock_adapter'
      @queue = MockAdapter.new(@name)
    end
  end

  def <<(object)
    queue.send serializer.dump(object)
  end

  def shift
    serializer.load queue.receive
  end
end
