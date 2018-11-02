# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |gem|
  gem.name          = "fluent-plugin-filter-docker_metadata"
  gem.version       = "0.0.1"
  gem.authors       = ["Al-waleed Shihadeh"]
  gem.email         = ["wshihadh@gmail.com"]
  gem.description   = %q{Filter plugin to add Docker metadata}
  gem.summary       = gem.summary
  gem.homepage      = "https://github.com/wshihadeh/fluent-plugin-filter-docker_metadat.git"
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}) { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.has_rdoc      = false

  gem.add_runtime_dependency "fluentd", ">= 0.14"
  gem.add_runtime_dependency "docker-api"
  gem.add_runtime_dependency "lru_redux"

  gem.add_development_dependency "bundler", "~> 1.3"
  gem.add_development_dependency "rake"
  gem.add_development_dependency "minitest", "~> 4.0"
  gem.add_development_dependency "test-unit", "~> 3.0.2"
  gem.add_development_dependency "test-unit-rr", "~> 1.0.3"
  gem.add_development_dependency "webmock"
  gem.add_development_dependency "vcr"
  gem.add_development_dependency "bump"
end
