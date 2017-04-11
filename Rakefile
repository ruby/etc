require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList['test/**/test_*.rb']
end

file("constdefs.h") do
  `ruby ext/etc/mkconstants.rb -o ext/etc/constdefs.h`
end

require "rake/extensiontask"
Rake::ExtensionTask.new("etc")
task :compile => "constdefs.h".to_sym

task :default => :test
