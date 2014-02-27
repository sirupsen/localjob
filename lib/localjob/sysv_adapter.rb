require 'sysvmq'

class Localjob
  class SysvAdapter
    RECEIVE_ALL_TYPES = 0

    attr_reader :queue

    def initialize(key, size: 8192, flags: SysVMQ::IPC_CREAT | 0660)
      @key = key
      @queue = SysVMQ.new(key, size, flags)
    end

    def receive
      queue.receive(RECEIVE_ALL_TYPES)
    end

    def send(message)
      queue.send(message, 1)
    end

    def size
      queue.stats[:count]
    end

    def stats
      queue.stats
    end

    def destroy
      queue.destroy
    end
  end
end
