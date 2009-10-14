require 'rubygems'
require 'spec/rake/spectask'

task :default => :spec

desc "Run specs"
Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.spec_opts = %w(-fs --color)
end

desc "Run all examples with RCov"
Spec::Rake::SpecTask.new(:rcov) do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.rcov = true
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "redis-model"
    gemspec.summary = "Minimal models for Redis"
    gemspec.description = "Minimal model support for redis-rb. Directly maps ruby properties to model_name:id:field_name keys in redis. Scalar, list and set properties are supported."
    gemspec.email = "voloko@gmail.com"
    gemspec.homepage = "http://github.com/voloko/redis-model"
    gemspec.authors = ["Vladimir Kolesnikov"]
    gemspec.add_dependency("redis", [">= 0.1.0"])
    gemspec.add_development_dependency("rspec", [">= 1.2.8"])
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end
