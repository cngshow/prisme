# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.
$CLASSPATH << "./lib/jars/ojdbc7.jar"
require File.expand_path('../config/application', __FILE__)
Rake.add_rakelib('./lib/rails_common/tasks')
Rails.application.load_tasks
Rake.application.options.trace = true #uncomment out to see stack traces in unit tests.
$rake = true

# Adding test/unit directory to rake test.
namespace :test do
  desc "Test tests/unit/lib/* code"
  Rails::TestTask.new(lib_unit: 'test:prepare') do |t|
    t.pattern = 'test/unit/lib/**/*_test.rb'
  end
end
# lib_unit = Rake::Task["test:lib_unit"]
# Rake::Task[:test].enhance do
#   lib_unit.invoke
# end