class Localjob
  class Worker
    TERMINATION_MESSAGE = "__TERMINATE__"

    attr_accessor :logger
    attr_reader :options, :queue

    def initialize(queue, logger: Logger.new(STDOUT), **options)
      @queue, @logger = queue, logger
      @queue = Localjob.new(@queue) if queue.kind_of?(Fixnum)
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

    def work(thread: false)
      logger.info "Worker #{pid} now listening!"
      trap_signals

      return work_thread if thread

      create_pid_file(@options[:pid_file])

      loop { break unless shift_and_process }
    end

    def kill
      if @thread
        Thread.kill(@thread)
        @thread.join
      else
        shutdown
      end
    end

    private

    def work_thread
      @thread = Thread.new do
        begin
          loop do
            shift_and_process
          end
        # Respond to Thread.kill by sending termination message
        ensure
          shutdown
          work
        end
      end
    end

    def shutdown!
      logger.info "Worker #{pid} shutting down.."
      File.rm(@options[:pid_file]) if @options[:pid_file]
      return false if @thread
      exit!
    end

    def shutdown
      @queue << TERMINATION_MESSAGE
    end

    def shift_and_process
      job = queue.shift
      return shutdown! if job == TERMINATION_MESSAGE || !job
      process(job)
      return true # Explicit return of true, job#perform may return nil
    rescue Object
      logger.error "Worker #{pid} job failed: #{job}"
      logger.error "#{$!}\n#{$@.join("\n")}"
    end

    def trap_signals
      Signal.trap("QUIT") { shutdown }
      Signal.trap("INT") { shutdown }
    end

    def create_pid_file(path)
      File.open(path, 'w') { |f| f << self.pid } if path
    end
  end
end
