class CreateSyncRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :sync_runs do |t|
      t.integer :generation
      t.string :status, null: false, default: "running"
      t.datetime :started_at
      t.datetime :finished_at
      t.integer :records_fetched, null: false, default: 0
      t.integer :records_created, null: false, default: 0
      t.integer :records_updated, null: false, default: 0
      t.integer :records_failed, null: false, default: 0
      t.integer :films_created, null: false, default: 0
      t.integer :films_updated, null: false, default: 0
      t.integer :venues_created, null: false, default: 0
      t.integer :venues_updated, null: false, default: 0
      t.integer :screenings_created, null: false, default: 0
      t.integer :screenings_updated, null: false, default: 0
      t.text :error_summary
      t.text :error_details

      t.timestamps
    end

    add_index :sync_runs, :status
    add_index :sync_runs, :started_at
  end
end
