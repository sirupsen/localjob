require "localjob/version"
require 'posix/mqueue'
require 'json'
require 'logger'

class Localjob
  def queue
    @queue ||= POSIX::Mqueue.new("/localjob")
  end

  def enqueue(klass, *args)
    queue.timedsend encode(klass, *args)
  end

  def size
    queue.size
  end

  def pop
    decode queue.receive
  end

  def destroy
    queue.unlink
  end

  def encode(klass, *args)
    JSON.dump 'class' => klass.to_s, 'args' => args
  end

  def decode(value)
    JSON.load value
  end

  def logger
    @logger ||= Logger.new(STDOUT)
  end

  def logger=(logger)
    @logger = logger
  end

  class Worker
    def initialize(queue)
      @queue = queue
      @shutdown = false
    end

    def process(job)
      Kernel.const_get(job["class"]).perform(*job["args"])
    end

    def pid
      Process.pid
    end

    def work
      trap_signals
      loop { pop_and_process }
    end

    def pop_and_process
      exit if @shutdown

      job = wait { queue.pop }
      logger.info "#{pid} got: #{job}"

      begin
        process job
      rescue Object => e
        logger.error "Worker #{pid} job failed: #{job}"
        logger.error "#{$!}\n#{$@}"
      end
    end

    private

    attr_reader :queue

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
