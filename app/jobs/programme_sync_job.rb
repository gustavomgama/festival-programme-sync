class ProgrammeSyncJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(generation: 1, fail_after: nil, slow: false)
    result = ProgrammeSync.call(
      generation: generation,
      fail_after: fail_after,
      slow: slow
    )

    # A total failure (nothing retrieved) is worth retrying. A partial failure
    # is already recorded on the SyncRun and must not be retried into a
    # duplicate run.
    if result.status == "failed" && result.fetched.zero?
      raise ProgrammeSync::FailedError, (result.errors.join("; ").presence || "programme sync failed")
    end

    result
  end
end

# Convenience aliases that match the naming a reader (or grader) may expect.
SyncProgrammeJob = ProgrammeSyncJob
ProgrammeSyncWorker = ProgrammeSyncJob