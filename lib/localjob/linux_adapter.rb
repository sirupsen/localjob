require 'posix/mqueue'

class Localjob
  class LinuxAdapter
    attr_reader :mqueue

    def initialize(name)
      @mqueue = POSIX::Mqueue.new(fix_queue_name(name))
    end

    def receive
      @mqueue.timedreceive
    end

    def send(message)
      @mqueue.timedsend message
    end

    def size
      @mqueue.size
    end

    def destroy
      @mqueue.unlink
    end

    def to_io
      @mqueue.to_io
    end

    private
    def fix_queue_name(name)
      name.start_with?('/') ? name : "/#{name}"
    end
  end
end
