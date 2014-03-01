require 'yaml'
require 'logger'
require 'forwardable'

require "localjob/version"
require 'localjob/worker'
require 'localjob/sysv_adapter'

class Localjob
  extend Forwardable

  attr_reader :name
  attr_accessor :queue

  def_delegators :queue, :to_io, :destroy, :size

  # LOCALJOB in 1337speak
  def initialize(name = 0x10CA110B)
    @name = name
  end

  def serializer
    YAML
  end

  def queue
    @queue ||= SysvAdapter.new(@name)
  end

  def <<(object)
    queue.send serializer.dump(object)
  end

  def shift
    serializer.load queue.receive
  end
end
