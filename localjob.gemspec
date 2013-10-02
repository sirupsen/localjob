# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'localjob/version'

Gem::Specification.new do |spec|
  spec.name          = "localjob"
  spec.version       = Localjob::VERSION
  spec.authors       = ["Simon Eskildsen"]
  spec.email         = ["sirup@sirupsen.com"]
  spec.description   = %q{Simple, self-contained background queue built on top of POSIX message queues.}
  spec.summary       = %q{Simple, self-contained background queue built on top of POSIX message queues. It only works on Linux.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "thor", "0.18.1"
  spec.add_dependency "SysVIPC"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "mocha"
end
