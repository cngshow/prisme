class CreateUserActivities < ActiveRecord::Migration
  def change
    create_table :user_activities do |t|
      t.string :username
      t.datetime :last_activity_at
      t.string :request_url
    end

    add_index :user_activities, [:username, :last_activity_at]
  end
end
