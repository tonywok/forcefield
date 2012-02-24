# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.authors       = ["Tony Schneider"]
  gem.email         = ["tony@edgecase.com"]
  gem.description   = %q{OAuth 1.0 RFC 5849#3.2 request verifier. Accompanies a blogpost, and is for learning purposes only.}
  gem.summary       = %q{OAuth 1.0 RFC 5849#3.2 request verifier}

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "forcefield"
  gem.require_paths = ["lib"]
  gem.version       = "0.0.1"

  gem.add_dependency 'rack', '~> 1.4'
  gem.add_dependency 'simple_oauth'
  gem.add_development_dependency 'rspec', '~> 2.7'
end
