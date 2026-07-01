class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch('MAILER_FROM', 'noreply@henslowescloud.com')
  layout 'mailer'
end
