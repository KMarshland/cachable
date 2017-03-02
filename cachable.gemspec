$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "cachable/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "cachable"
  s.version     = Cachable::VERSION
  s.authors     = ["Kai Marshland"]
  s.email       = ["kaimarshland@gmail.com"]
  s.homepage    = "https://github.com/KMarshland/cachable"
  s.summary     = "Easily add caching to models"
  s.description = "Easily add caching to models"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", ">= 4.0.0"
  s.add_dependency "redis", ">= 3.0"

  s.add_development_dependency "sqlite3"
end
