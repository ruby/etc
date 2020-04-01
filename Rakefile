require "bundler/gem_tasks"
require "rake/testtask"

name = "etc"

headers = ["ext/etc/constdefs.h"]
task compile: headers
task build: headers
file "ext/etc/constdefs.h" => "ext/etc/mkconstants.rb" do |t|
  ruby t.prerequisites.first, "-o", t.name
end

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/test_*.rb"]
end

require 'rake/extensiontask'
Rake::ExtensionTask.new(name)
task :default => :test
