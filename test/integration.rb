require 'localjob'

class PrintJob
  def perform
    puts "hello world"
  end
end

if ARGV[0] == "produce"
  queue = Localjob.new
  queue << PrintJob.new
end
