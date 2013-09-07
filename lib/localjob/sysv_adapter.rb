require 'SysVIPC'

class Localjob
  class Channel
    def shift
      raise "SysV adapter does not support multiple queues" if @queues.size > 1
      @queues.first.shift
    end
  end

  class SysvAdapter
    include SysVIPC
    attr_reader :mqueue

    def initialize(name)
      @filename = "/tmp/#{name}"
      File.open(@filename, "w") { }
      key = ftok(@filename, 0)

      @mq = MessageQueue.new(key, IPC_CREAT | 0600)
    end

    def receive
      @mq.receive(0, 1024)
    end

    def send(message)
      @mq.send(1, message)
    end

    def size
      @mq.ipc_stat.msg_qnum
    end

    def destroy
      File.delete(@filename)
      @mq.rm
    end

    private
    def fix_queue_name(name)
      name.start_with?('/') ? name : "/#{name}"
    end
  end
end
