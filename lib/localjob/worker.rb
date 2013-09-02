class Localjob
  class Worker
    attr_accessor :logger, :channel

    def initialize(queues, logger: Logger.new(STDOUT))
      @channel = Channel.new(queues)
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
      job = wait { @channel.shift }

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
  end
end
