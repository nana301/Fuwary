require "active_support/core_ext/integer/time"

Rails.application.configure do

  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.default_url_options = {
    host: ENV.fetch("APP_HOST", ENV["RENDER_EXTERNAL_HOSTNAME"]),
    protocol: "https"
  }

  if ENV["SMTP_ADDRESS"].present? && ENV["SMTP_USERNAME"].present? && ENV["SMTP_PASSWORD"].present?
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      address: ENV["SMTP_ADDRESS"],
      port: (ENV["SMTP_PORT"] || 587).to_i,
      domain: ENV["SMTP_DOMAIN"] || ENV.fetch("APP_HOST", ENV["RENDER_EXTERNAL_HOSTNAME"]),
      user_name: ENV["SMTP_USERNAME"],
      password: ENV["SMTP_PASSWORD"],
      authentication: :plain,
      enable_starttls_auto: true
    }

    config.action_mailer.default_options = {
      from: ENV.fetch("MAIL_FROM", "no-reply@#{ENV.fetch('APP_HOST', ENV['RENDER_EXTERNAL_HOSTNAME'])}")
    }
  else
    config.action_mailer.perform_deliveries = false
  end
end
