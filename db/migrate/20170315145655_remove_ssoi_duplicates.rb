class RemoveSsoiDuplicates < ActiveRecord::Migration
  def change
    # clean up any duplicate ssoi user records based on the ssoi_user_name
    all_users = SsoiUser.all.to_a
    all_names = []
    all_users.each do |user|
        user.delete if all_names.include? user.ssoi_user_name
        all_names << user.ssoi_user_name
    end
  end
end
