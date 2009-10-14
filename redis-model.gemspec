# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{redis-model}
  s.version = "0.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Vladimir Kolesnikov"]
  s.date = %q{2009-10-14}
  s.description = %q{Minimal model support for redis-rb. Directly maps ruby properties to model_name:id:field_name keys in redis. Scalar, list and set properties are supported.}
  s.email = %q{voloko@gmail.com}
  s.extra_rdoc_files = [
    "README.markdown"
  ]
  s.files = [
    ".gitignore",
     "README.markdown",
     "Rakefile",
     "VERSION",
     "bench.rb",
     "examples/model.rb",
     "lib/redis/model.rb",
     "redis-model.gemspec",
     "spec/redis/model_spec.rb",
     "spec/spec_helper.rb"
  ]
  s.homepage = %q{http://github.com/voloko/redis-model}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Minimal models for Redis}
  s.test_files = [
    "spec/redis/model_spec.rb",
     "spec/spec_helper.rb",
     "examples/model.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<redis>, [">= 0.1.0"])
    else
      s.add_dependency(%q<redis>, [">= 0.1.0"])
    end
  else
    s.add_dependency(%q<redis>, [">= 0.1.0"])
  end
end
