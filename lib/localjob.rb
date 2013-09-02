require "localjob/version"
require 'posix/mqueue'
require 'yaml'
require 'logger'

class Localjob
  attr_reader :queue_name

  attr_accessor :logger

  def initialize(serializer: YAML, queue: "/localjob", logger: Logger.new(STDOUT))
    @serializer, @queue_name = serializer, queue
    @logger = logger
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
    @serializer.load queue.receive
  end

  def destroy
    queue.unlink
  end

  class Worker
    def initialize(queue)
      @queue = queue
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

    attr_reader :queue

    def shift_and_process
      exit if @shutdown

      job = wait { queue.shift }
      logger.info "#{pid} got: #{job}"

      begin
        process job
      rescue Object => e
        logger.error "Worker #{pid} job failed: #{job}"
        logger.error "#{$!}\n#{$@.join("\n")}"
      end
    end

    def trap_signals
      Signal.trap("QUIT") { graceful_shutdown }
    end

    def wait
      @waiting = true
      job = yield
      @waiting = false
      job
    end

    def graceful_shutdown
      exit if @waiting
      @shutdown = true
    end

    def logger
      queue.logger
    end
  end
end
