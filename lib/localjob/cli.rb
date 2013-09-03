require 'thor'

class Localjob
  class CLI < Thor
    option :queues,    aliases: ["-q"], type: :string, default: "localjob"
    option :require,   aliases: ["-r"], type: :string, default: "."
    option :pid_file,  aliases: ["-p"], type: :string
    option :daemon,    aliases: ["-d"], type: :boolean
    desc "work", "Start worker to process jobs"
    def work
      load_environment options[:require]

      queues = options[:queues].split(",")
      Localjob::Worker.new(queues, options.slice(:daemon, :pid_file)).work
    end

    desc "size", "Outputs the size of queues"
    option :queues, aliases: ["-q"], type: :string, default: "localjob"
    def size
      queues = options[:queues].split(",")
      queues.each do |queue|
        puts "Size of /#{queue}: #{Localjob.new(queue).size}/#{msg_max}"
      end
    end

    desc "destroy", "Destroys all queues passed"
    option :queues, aliases: ["-q"], type: :string, default: "localjob"
    def destroy
      options[:queues].split(",").each do |queue|
        Localjob.new(queue).destroy
      end
    end

    desc "list", "Lists all queues"
    def list
      unless File.exists?("/dev/mqueue")
        system "mkdir /dev/mqueue"
        system "mount -t mqueue none /dev/mqueue"
      end

      system "ls -l /dev/mqueue"
    end

    private
    def load_environment(file)
      if rails?(file)
        require 'rails'
        require File.expand_path("#{file}/config/environment.rb")
        ::Rails.application.eager_load!
      elsif File.file?(file)
        require File.expand_path(file)
      else
        puts "No require path passed, requires -r if not in Rails"
        exit
      end
    end

    def rails?(file)
      File.exists?(File.expand_path("#{file}/config/environment.rb"))
    end

    def msg_max
      @msg_max ||= File.read("/proc/sys/fs/mqueue/msg_max")
    end
  end
end
