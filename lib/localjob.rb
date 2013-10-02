require 'yaml'
require 'logger'
require 'forwardable'

require "localjob/version"
require 'localjob/channel'
require 'localjob/worker'
require 'localjob/sysv_adapter'

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
    @queue ||= SysvAdapter.new(@name)
  end

  def <<(object)
    queue.send serializer.dump(object)
  end

  def shift
    serializer.load queue.receive
  end
end
