class ProgrammeSyncJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(generation: 1, fail_after: nil, slow: false)
    result = ProgrammeSync.call(
      generation: generation,
      fail_after: fail_after,
      slow: slow
    )

    if result.status == "failed" && result.fetched.zero?
      raise ProgrammeSync::FailedError, (result.errors.join("; ").presence || "programme sync failed")
    end

    result
  end
end

SyncProgrammeJob = ProgrammeSyncJob
ProgrammeSyncWorker = ProgrammeSyncJob