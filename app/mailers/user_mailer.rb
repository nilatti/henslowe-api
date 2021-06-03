class UserMailer < Devise::Mailer
  # helper :application # gives access to all helpers defined within `application_helper`.
  default template_path: 'users/mailer' # to make sure that your mailer uses the devise views
  default from: "henslowescloud@gmail.com"

  def reset_password_instructions(record, token, opts={})
    @resource = record
    @token = token
      mail(to: record.email, subject: "Your Awesome password!")
  end

  private

  def create_reset_password_token(user)
    raw, hashed = Devise.token_generator.generate(User, :reset_password_token)
    @token = raw
    user.reset_password_token = hashed
    user.reset_password_sent_at = Time.now.utc
    user.save
  end
end
