class Localjob::Cli
  def initialize(file)
    @file = file
  end

  def setup
    valid_file?

    if rails?
      require 'rails'
      require File.expand_path("#{file}/config/environment.rb")
      ::Rails.application.eager_load!
    else
      require File.expand_path(file)
    end
  end

  private
  attr_reader :file

  def valid_file?
    raise "No file passed" unless defined?(file) && File.directory?(file)
  end

  def rails?
    File.exists?(File.expand_path("#{file}/config/environment.rb"))
  end
end
