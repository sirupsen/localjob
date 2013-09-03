require 'rubygems'
require 'rubygems/command.rb'
require 'rubygems/dependency_installer.rb' 
begin
  Gem::Command.build_args = ARGV
rescue NoMethodError
end 

inst = Gem::DependencyInstaller.new

begin
  if RUBY_PLATFORM =~ /linux/
    inst.install "posix-mqueue", "0.0.7"
  end
rescue
  exit(1)
end 
