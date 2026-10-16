require "securerandom"

class ProgrammeSyncJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(generation: 1, fail_after: nil, slow: false)
    lock_key = "programme_sync:execution_lock"
    lock_token = SecureRandom.uuid
    acquired = true
    begin
      acquired = Sidekiq.redis { |conn| conn.set(lock_key, lock_token, nx: true, ex: 1800) == "OK" }
    rescue => e
      Rails.logger.warn("programme_sync.lock.unavailable: #{e.class}: #{e.message}")
      acquired = true
      lock_token = nil
    end

    result =
      if acquired
        begin
          ProgrammeSync.call(generation: generation, fail_after: fail_after, slow: slow)
        ensure
          if lock_token
            Sidekiq.redis { |conn| conn.eval("if redis.call('get', KEYS[1]) == ARGV[1] then return redis.call('del', KEYS[1]) else return 0 end", 1, lock_key, lock_token) }
          end
        end
      else
        ProgrammeSync::Result.new(status: "skipped", sync_run_id: nil, fetched: 0, created: 0, updated: 0, unchanged: 0, skipped: 0, failed: 0, errors: [ "another sync run is in progress" ])
      end

    if result.status == "failed" && result.fetched.zero?
      raise ProgrammeSync::FailedError, (result.errors.join("; ").presence || "programme sync failed")
    end

    result
  end
end
