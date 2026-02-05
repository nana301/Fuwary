# ---- Action Mailer ----
config.action_mailer.perform_deliveries = true
config.action_mailer.raise_delivery_errors = false

config.action_mailer.default_url_options = {
  host: ENV.fetch("APP_HOST", ENV["RENDER_EXTERNAL_HOSTNAME"]),
  protocol: "https"
}

# SMTP環境変数が揃っているときだけSMTPを使う（無ければ落とさない）
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
    from: ENV.fetch("MAIL_FROM", "no-reply@#{ENV.fetch("APP_HOST", ENV['RENDER_EXTERNAL_HOSTNAME'])}")
  }
else
  # SMTP未設定ならメール送信を止める（＝confirmable等があってもビルドが落ちない）
  config.action_mailer.perform_deliveries = false
end
