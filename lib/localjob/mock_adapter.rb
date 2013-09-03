class Localjob
  class Channel
    def shift
      queue = @queues.find { |q| q.size > 0 }
      return queue.shift
    end
  end

  class MockAdapter
    def initialize(name = 'default')
      @@queues ||= {}
      @name = name 
      @@queues[@name] ||= []
    end

    def receive
      @@queues[@name].shift
    end

    def send(message)
      @@queues[@name] << message
    end

    def size
      @@queues[@name].size
    end

    def destroy
      @@queues[@name] = nil
    end
  end
end
