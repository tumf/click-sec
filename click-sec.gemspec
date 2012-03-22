# -*- encoding: utf-8 -*-
require File.expand_path('../lib/stocktrade/clicksec/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Yoshihiro TAKAHARA"]
  gem.email         = ["y.takahara@gmail.com"]
  gem.description   = %q{click-sec}
  gem.summary       = %q{click-sec tools}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "click-sec"
  gem.require_paths = ["lib"]
  gem.version       = StockTrade::ClickSec::VERSION
end
