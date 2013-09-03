class Localjob
  class Worker
    attr_accessor :logger, :channel

    def initialize(queues, logger: Logger.new(STDOUT), pid_file: false, deamon: false)
      @channel, @logger = Channel.new(queues), logger
      create_pid_file(pid_file)
      deamonize if deamon
      @shutdown = false
    end

    def process(job)
      job.perform
    end

    def pid
      Process.pid
    end

    def work
      logger.info "Worker #{pid} now listening!"
      trap_signals
      loop { shift_and_process }
    end

    private

    def shift_and_process
      exit if @shutdown

      begin
        job = wait { @channel.shift }

        logger.info "Worker #{pid}: #{job.inspect}"
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

    def deamonize
      Process.daemon(true, true)
    end

    def create_pid_file(path)
      File.open(path, 'w') { |f| f << self.pid } if path
    end

    def graceful_shutdown
      exit! if @waiting
      @shutdown = true
    end
  end
end
