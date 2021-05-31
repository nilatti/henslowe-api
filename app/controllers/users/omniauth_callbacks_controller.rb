class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def failure
    puts(request.env["omniauth.auth"])
    puts "failure_message"
    # set_flash_message! :alert, :failure, kind: OmniAuth::Utils.camelize(failed_strategy.name), reason: failure_message
    redirect_to after_omniauth_failure_path_for(resource_name)
  end

  def google_oauth2
    # You need to implement the method below in your model (e.g. app/models/user.rb)
    @user = User.from_omniauth(request.env["omniauth.auth"])
    puts (@user)
    if @user.persisted?
        puts "user persisted!"
        render json: @user, event: :authentication #this will throw if @user is not activated
    else
      puts "user not persisted!"
      session["devise.google_oauth2_data"] = request.env["omniauth.auth"]
      puts session["devise.google_oauth2_data"]
      redirect_to new_user_registration_url
    end
  end

  def failure
    redirect_to root_path
  end
end
