# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'swarm/sequel/version'

Gem::Specification.new do |spec|
  spec.name          = "swarm-sequel"
  spec.version       = Swarm::Sequel::VERSION
  spec.authors       = ["Ravi Gadad"]
  spec.email         = ["ravi@renewfund.com"]

  spec.summary       = %q{A Swarm storage class using the Sequel ORM}
  spec.homepage      = "https://github.com/bumbleworks/swarm-sequel"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "swarm", "~> 0.2"
  spec.add_dependency "sequel"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "timecop"
  spec.add_development_dependency "sqlite3"
end
