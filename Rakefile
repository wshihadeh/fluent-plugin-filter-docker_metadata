require "bundler/gem_tasks"
require "rake/testtask"
require "bump/tasks"

task :test => [:base_test]

task :default => [:test, :build]

desc 'Run test_unit based test'
Rake::TestTask.new(:base_test) do |t|
  t.libs << "test"
  t.test_files = Dir["test/**/test_*.rb"].sort
  #t.verbose = true
  t.warning = false
end
