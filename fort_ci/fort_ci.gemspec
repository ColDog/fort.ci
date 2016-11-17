# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fort_ci/version'

Gem::Specification.new do |spec|
  spec.name          = "fort_ci"
  spec.version       = SimpleCi::VERSION
  spec.authors       = ["Colin Walker"]
  spec.email         = ["colinwalker270@gmail.com"]

  spec.summary       = %q{SimpleCI Tool}
  spec.homepage      = "TODO: Put your gem's website or public repo URL here."

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "mysql2"

  spec.add_dependency "activerecord", ">= 5.0.0"
  spec.add_dependency "actionpack", ">= 5.0.0"
  spec.add_dependency "activesupport", ">= 5.0.0"
  spec.add_dependency "sinatra", "~> 2.0.0.beta2"
  spec.add_dependency "sinatra-contrib", "~> 2.0.0.beta2"
  spec.add_dependency "rack", "~> 2.0"
  spec.add_dependency "omniauth", "~> 1.3"
  spec.add_dependency "omniauth-bitbucket", "~> 0.0.2"
  spec.add_dependency "omniauth-github", "~> 1.1.2"
  spec.add_dependency "active_model_serializers", "~> 0.10"
  spec.add_dependency "puma", "~> 3.6"
  spec.add_dependency "faraday"
  spec.add_dependency "jwt"
  spec.add_dependency "simpleci-worker", "0.1.3"
end
