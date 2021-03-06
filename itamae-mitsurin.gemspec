# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'itamae-mitsurin/version'

Gem::Specification.new do |spec|
  spec.name          = "itamae-mitsurin"
  spec.version       = ItamaeMitsurin::VERSION
  spec.authors       = ["Akihiro Kamiyama"]
  spec.email         = ["akihiro.vamps@gmail.com"]
  spec.summary       = %q{Customized version of Itamae and Itamae plugin.
configuration management tool like chef.
Deploy without the agent.
It can be deployed using the AWS Resources.}
  spec.homepage      = "https://github.com/kammy1231/itamae-mitsurin"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  spec.required_ruby_version = Gem::Requirement.new(">= 2.0")

  spec.add_runtime_dependency "thor"
  spec.add_runtime_dependency "hashie"
  spec.add_runtime_dependency "ansi"
  spec.add_runtime_dependency "schash", "~> 0.1.0"
  spec.add_runtime_dependency "aws-sdk", "~> 2"
  spec.add_runtime_dependency "serverspec", [">= 2.30", "< 3.0.0"]
  spec.add_runtime_dependency "highline"
  spec.add_runtime_dependency "rake"
  spec.add_runtime_dependency "json"
  spec.add_runtime_dependency "io-console"
  spec.add_runtime_dependency "bundler"
  spec.add_runtime_dependency "tempdir"

  spec.add_development_dependency "rake-compiler"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "docker-api", "~> 1.20"
  spec.add_development_dependency "fakefs"
  spec.add_development_dependency "fluent-logger"
end
