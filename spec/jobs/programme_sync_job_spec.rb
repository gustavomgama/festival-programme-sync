require "rails_helper"

RSpec.describe ProgrammeSyncJob, type: :job do
  before do
    Screening.delete_all
    Venue.delete_all
    Film.delete_all
    SyncRun.delete_all
  end

  it "runs the sync and records a SyncRun" do
    result = described_class.perform_now(generation: 1)

    expect(result.status).to eq("success")
    expect(SyncRun.count).to eq(1)
    expect(SyncRun.last.status).to eq("success")
  end

  it "skips when the execution lock is already held" do
    lock_key = "programme_sync:execution_lock"
    Sidekiq.redis { |conn| conn.set(lock_key, "other-token", nx: true, ex: 60) }

    result = described_class.perform_now(generation: 1)

    expect(result.status).to eq("skipped")
    expect(SyncRun.count).to eq(0)
  ensure
    Sidekiq.redis { |conn| conn.del(lock_key) }
  end
end
