require 'yaml'
require 'logger'
require 'forwardable'

require "localjob/version"
require 'localjob/channel'
require 'localjob/worker'

case RUBY_PLATFORM
when /linux/
  require 'localjob/linux_adapter'
else
  require 'localjob/sysv_adapter'
end

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
      @queue = LinuxAdapter.new(@name)
    else
      @queue = SysvAdapter.new(@name)
    end
  end

  def <<(object)
    queue.send serializer.dump(object)
  end

  def shift
    serializer.load queue.receive
  end
end
