# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)
Rake.add_rakelib('./lib/rails_common/tasks')
Rails.application.load_tasks

def running_tasks
  @running_tasks ||= Rake.application.top_level_tasks
end

def is_running_migration_or_rollback?
  running_tasks.include?("db:migrate") || running_tasks.include?("db::rollback")
end