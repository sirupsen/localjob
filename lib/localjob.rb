require "localjob/version"
require 'posix/mqueue'
require 'yaml'
require 'logger'

class Localjob
  attr_reader :queue_name

  def initialize(serializer: YAML, queue: "/localjob")
    @serializer, @queue_name = serializer, queue
  end

  def queue
    @queue ||= POSIX::Mqueue.new(@queue_name)
  end

  def <<(object)
    queue.timedsend @serializer.dump(object)
  end

  def size
    queue.size
  end

  def shift
    @serializer.load queue.timedreceive
  end

  def destroy
    queue.unlink
  end

  def to_io
    queue.to_io
  end

  class Worker
    attr_accessor :queues, :logger

    def initialize(queue, logger: Logger.new(STDOUT))
      @queues = [queue].flatten
      @shutdown = false
    end

    def process(job)
      job.perform
    end

    def pid
      Process.pid
    end

    def work
      trap_signals
      loop { shift_and_process }
    end

    private

    def shift_and_process
      exit if @shutdown
      job = reserve

      begin
        logger.info "#{pid} got: #{job}"
        process job
      rescue Object => e
        logger.error "Worker #{pid} job failed: #{job}"
        logger.error "#{$!}\n#{$@.join("\n")}"
      end
    end

    def trap_signals
      Signal.trap("QUIT") { graceful_shutdown }
    end

    def multiple_queue_shift
      (queue,), = IO.select(@queues)
      queue.shift
    rescue POSIX::Mqueue::QueueEmpty
      retry
    end

    def reserve
      @waiting = true
      job = multiple_queue_shift
      @waiting = false
      job
    end

    def graceful_shutdown
      exit if @waiting
      @shutdown = true
    end
  end
end
