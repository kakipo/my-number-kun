# -*- encoding: utf-8 -*-
# stub: heroku-api 0.3.23 ruby lib

Gem::Specification.new do |s|
  s.name = "heroku-api"
  s.version = "0.3.23"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["geemus (Wesley Beary)", "Pedro Belo"]
  s.date = "2015-03-19"
  s.description = "Ruby Client for the Heroku API"
  s.email = ["wesley@heroku.com", "pedro@heroku.com"]
  s.homepage = "http://github.com/heroku/heroku.rb"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.2.2"
  s.summary = "Ruby Client for the Heroku API"

  s.installed_by_version = "2.2.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<excon>, ["~> 0.44"])
      s.add_runtime_dependency(%q<multi_json>, ["~> 1.8"])
      s.add_development_dependency(%q<minitest>, [">= 0"])
      s.add_development_dependency(%q<rake>, [">= 0"])
    else
      s.add_dependency(%q<excon>, ["~> 0.44"])
      s.add_dependency(%q<multi_json>, ["~> 1.8"])
      s.add_dependency(%q<minitest>, [">= 0"])
      s.add_dependency(%q<rake>, [">= 0"])
    end
  else
    s.add_dependency(%q<excon>, ["~> 0.44"])
    s.add_dependency(%q<multi_json>, ["~> 1.8"])
    s.add_dependency(%q<minitest>, [">= 0"])
    s.add_dependency(%q<rake>, [">= 0"])
  end
end
