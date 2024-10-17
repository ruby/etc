require "bundler/gem_tasks"
require "rake/testtask"
require "rdoc/task"

name = "etc"

headers = ["ext/etc/constdefs.h"]
task compile: headers
task build: headers
file "ext/etc/constdefs.h" => "ext/etc/mkconstants.rb" do |t|
  ruby t.prerequisites.first, "-o", t.name
end

require 'rake/extensiontask'
extask = Rake::ExtensionTask.new(name) do |x|
  x.lib_dir.sub!(%r[(?=/|\z)], "/#{RUBY_VERSION}/#{x.platform}")
end
Rake::TestTask.new(:test) do |t|
  t.libs.unshift(extask.lib_dir)
  t.libs << "test/lib"
  t.ruby_opts << "-rhelper"
  t.test_files = FileList["test/**/test_*.rb"]
end

task "rdoc" =>  "changelogs"
RDoc::Task.new do |rdoc|
  rdoc.main = "README.md"
end

task :test => :compile

task :default => :test
