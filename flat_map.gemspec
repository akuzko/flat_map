# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "flat_map/version"

Gem::Specification.new do |s|
  s.name        = "flat_map"
  s.version     = FlatMap::VERSION
  s.authors     = ["TMX Credit", "Artem Kuzko", "Zachary Belzer", "Sergey Potapov"]
  s.email       = ["rubygems@tmxcredit.com", "a.kuzko@gmail.com", "zbelzer@gmail.com", "blake131313@gmail.com"]
  s.homepage    = "https://github.com/TMXCredit/flat_map"
  s.licenses    = ["LICENSE"]
  s.summary     = %q{Deep object graph to a plain properties mapper}
  s.description = %q{This library allows to map accessors and properties of deeply
    nested object graph to a plain mapper object with flexible behavior}

  s.rubyforge_project = "flat_map"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_dependency(%q<activesupport>, [">= 3.2"])
  s.add_dependency(%q<activerecord>, [">= 3.2"])
  s.add_dependency(%q<yard>, [">= 0"])

  s.add_development_dependency "rspec"
  s.add_development_dependency "rake"
end
