class AddUnchangedCountsToSyncRuns < ActiveRecord::Migration[8.1]
  def change
    add_column :sync_runs, :records_unchanged, :integer, null: false, default: 0
    add_column :sync_runs, :screenings_unchanged, :integer, null: false, default: 0
    add_column :sync_runs, :films_unchanged, :integer, null: false, default: 0
    add_column :sync_runs, :venues_unchanged, :integer, null: false, default: 0
    add_column :sync_runs, :records_skipped, :integer, null: false, default: 0
  end
end
