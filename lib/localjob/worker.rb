class Localjob
  class Worker
    attr_accessor :logger, :channel
    attr_reader :options

    def initialize(queues, logger: Logger.new(STDOUT), **options)
      @channel, @logger = Channel.new(queues), logger
      @options = options
      @shutdown = false
    end

    def process(job)
      logger.info "Worker #{pid}: #{job.inspect}"
      job.perform
    end

    def pid
      Process.pid
    end

    def work
      logger.info "Worker #{pid} now listening!"
      trap_signals
      create_pid_file(@options[:pid_file])
      deamonize if @options[:deamon]
      loop { shift_and_process }
    end

    private

    def shift_and_process
      exit! if @shutdown

      job = wait { @channel.shift }
      process job
    rescue Object => e
      logger.error "Worker #{pid} job failed: #{job}"
      logger.error "#{$!}\n#{$@.join("\n")}"
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
