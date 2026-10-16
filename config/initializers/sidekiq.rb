redis_url = ENV.fetch("REDIS_URL", "redis://localhost:6379/0")

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url }

  begin
    require "sidekiq/cron"
    Sidekiq::Cron::Job.create(
      name: "hourly programme sync",
      cron: "0 * * * *",
      class: "ProgrammeSyncJob",
      queue: "default"
    )
  rescue LoadError, StandardError => e
    Rails.logger.warn("sidekiq.schedule.unavailable: #{e.class}: #{e.message}")
  end
end

Sidekiq.configure_client { |config| config.redis = { url: redis_url } }
