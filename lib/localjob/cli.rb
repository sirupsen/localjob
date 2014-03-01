require 'thor'

class Localjob
  class CLI < Thor
    option :queue,     aliases: ["-q"], type: :string, default: "0x10CA110B"
    option :require,   aliases: ["-r"], type: :string, default: "."
    option :pid_file,  aliases: ["-p"], type: :string
    option :daemon,    aliases: ["-d"], type: :boolean
    desc "work", "Start worker to process jobs"
    def work
      load_environment options[:require]
      Localjob::Worker.new(queue.to_i(16), options.slice(:daemon, :pid_file)).work
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
