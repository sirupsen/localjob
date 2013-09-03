class Localjob
  class Channel
    attr_accessor :queues

    def initialize(queues)
      @queues = [queues].flatten.map { |q| queue_from_name(q) }
    end

    def <<(queue)
      @queues << queue_from_name(queue)
    end

    def shift
      (queue,), = IO.select(@queues)
      queue.shift
    rescue POSIX::Mqueue::QueueEmpty
      retry
    end

    private
    def queue_from_name(queue)
      queue.instance_of?(Localjob) ? queue : Localjob.new(queue)
    end
  end
end
