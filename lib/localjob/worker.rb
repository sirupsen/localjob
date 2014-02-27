class Localjob
  class Worker
    TERMINATION_MESSAGE = "__TERMINATE__"

    attr_accessor :logger
    attr_reader :options, :queue

    def initialize(queue, logger: Logger.new(STDOUT), **options)
      @queue, @logger = queue, logger
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

      job = queue.shift
      exit! if job == TERMINATION_MESSAGE
      # This means serialization failed
      raise "Invalid job: #{job}" unless job
      process job
    rescue Object
      logger.error "Worker #{pid} job failed: #{job}"
      logger.error "#{$!}\n#{$@.join("\n")}"
    end

    def trap_signals
      Signal.trap("QUIT") do
        @queue << TERMINATION_MESSAGE
      end
    end

    def deamonize
      Process.daemon(true, true)
    end

    def create_pid_file(path)
      File.open(path, 'w') { |f| f << self.pid } if path
    end
  end
end
