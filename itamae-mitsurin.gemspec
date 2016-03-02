# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'itamae/mitsurin/version'

Gem::Specification.new do |spec|
  spec.name          = "itamae-mitsurin"
  spec.version       = Itamae::Mitsurin::VERSION
  spec.authors       = ["Akihiro Kamiyama"]
  spec.email         = ["akihiro.vamps@gmail.com"]
  spec.summary       = %q{Customized version of Itamae and Itamae plugin}
  spec.homepage      = "https://github.com/kammy1231/itamae-mitsurin"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "thor"
  spec.add_runtime_dependency "specinfra", [">= 2.51.2", "< 3.0.0"]
  spec.add_runtime_dependency "hashie"
  spec.add_runtime_dependency "ansi"
  spec.add_runtime_dependency "schash", "~> 0.1.0"
  spec.add_runtime_dependency "aws-sdk", "~> 2"
  spec.add_runtime_dependency "serverspec", [">= 2.30", "< 3.0.0"]
  spec.add_runtime_dependency "rake"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "docker-api", "~> 1.20"
  spec.add_development_dependency "fakefs"
  spec.add_development_dependency "fluent-logger"
end
