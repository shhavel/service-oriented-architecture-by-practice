configure :production do
  Rusen.settings.outputs = [:pony]
  Rusen.settings.sections = [:backtrace, :environment]
  Rusen.settings.email_prefix = "[ERROR Divisor API] "
  Rusen.settings.sender_address = "your-email@gmail.com"
  Rusen.settings.exception_recipients = %w(your-email@gmail.com)
  Rusen.settings.smtp_settings = {
    address: "smtp.gmail.com",
    port: 587,
    domain: "mail.google.com",
    authentication: :plain,
    user_name: "your-email@gmail.com",
    password: "xxxxxxxx",
    enable_starttls_auto: true
  }
end

configure :development, :test do
  Rusen.settings.outputs = [:io]
  Rusen.settings.sections = [:backtrace, :environment]
end
