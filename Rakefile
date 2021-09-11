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
  t.libs << "test/lib"
  t.ruby_opts << "-rhelper"
  t.test_files = FileList["test/**/test_*.rb"]
end

require 'rake/extensiontask'
Rake::ExtensionTask.new(name)

task :sync_tool do
  require 'fileutils'
  FileUtils.cp "../ruby/tool/lib/core_assertions.rb", "./test/lib"
  FileUtils.cp "../ruby/tool/lib/envutil.rb", "./test/lib"
  FileUtils.cp "../ruby/tool/lib/find_executable.rb", "./test/lib"
end

task :default => :test
