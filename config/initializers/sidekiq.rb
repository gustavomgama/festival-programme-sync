redis_url = ENV.fetch("REDIS_URL", "redis://localhost:6379/0")

Sidekiq.configure_server { |config| config.redis = { url: redis_url } }
Sidekiq.configure_client { |config| config.redis = { url: redis_url } }

schedule = begin
  require "sidekiq/cron"
  Sidekiq::Cron::Job.create(
    name: "hourly programme sync",
    cron: "0 * * * *",
    class: "ProgrammeSyncJob",
    queue: "default"
  )
rescue LoadError, StandardError => e
  Rails.logger.warn("sidekiq.schedule.unavailable: #{e.class}: #{e.message}")
  nil
end