class AddPausedColumnsToSubscriptions < ActiveRecord::Migration[7.1]
  def change
    add_column :subscriptions, :paused_at, :datetime
    add_column :subscriptions, :user_requested_pause_at, :datetime
  end
end
