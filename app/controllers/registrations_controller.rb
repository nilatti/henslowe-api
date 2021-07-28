class RegistrationsController < Devise::RegistrationsController
  # skip_before_action :doorkeeper_authorize!, only: %i[create]
  respond_to :json

  def create
    build_resource(sign_up_params)
    resource.save
    resource.errors.each {|e| puts e.full_message}
    render json: resource
  end

  def update
    @user = User.find_by_email(user_params[:email])

    if @user.update_attributes(user_params)
      render json: @user
    else
      warden.custom_failure!
      render :json=> @user.errors, :status=>422
    end
 end

  def destroy
    @user = User.find_by_email(user_params[:email])
    if @user.destroy
      render :json=> { success: 'user was successfully deleted' }, :status=>201
    else
      render :json=> { error: 'user could not be deleted' }, :status=>422
    end
  end

  private

  def user_params
     params.require(:user).permit(
       :bio,
       :birthdate,
       :city,
       :description,
       :email,
       :emergency_contact_name,
       :emergency_contact_number,
       :first_name,
       :gender,
       :password,
       :password_confirmation,
       :last_name,
       :middle_name,
       :phone_number,
       :preferred_name,
       :program_name,
       :state,
       :street_address,
       :timezone,
       :website,
       :zip
     )

  end
end
