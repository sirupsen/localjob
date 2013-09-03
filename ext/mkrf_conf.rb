require 'rubygems/dependency_installer' 

gem = Gem::DependencyInstaller.new
gem.install "posix-mqueue", "0.0.7" if RUBY_PLATFORM =~ /linux/
