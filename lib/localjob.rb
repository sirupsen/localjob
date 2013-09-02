require 'posix/mqueue'
require 'yaml'
require 'logger'

require "localjob/version"
require 'localjob/channel'
require 'localjob/worker'

class Localjob
  attr_reader :queue_name

  def initialize(queue = "localjob")
    @queue_name = fix_queue_name(queue)
  end

  def serializer
    YAML
  end

  def queue
    @queue ||= POSIX::Mqueue.new(@queue_name)
  end

  def <<(object)
    queue.timedsend serializer.dump(object)
  end

  def size
    queue.size
  end

  def shift
    serializer.load queue.timedreceive
  end

  def destroy
    queue.unlink
  end

  def to_io
    queue.to_io
  end

  private
  def fix_queue_name(queue)
    queue.start_with?('/') ? queue : "/#{queue}"
  end
end
