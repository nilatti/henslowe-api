class ApplicationController < ActionController::Base
  # protect_from_forgery unless: -> { request.format.json? }
  skip_forgery_protection
  before_action :configure_permitted_parameters, if: :devise_controller?
  protected
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [
      :bio,
      :birthdate,
      :city,
      :description,
      :emergency_contact_name,
      :emergency_contact_number,
      :first_name,
      :gender,
      :email,
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
    ])
    devise_parameter_sanitizer.permit(:account_update, keys: [
      :bio,
      :birthdate,
      :city,
      :description,
      :emergency_contact_name,
      :emergency_contact_number,
      :first_name,
      :gender,
      :email,
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
    ])
  end

    def render_resource(resource)
      if resource.errors.empty?
        render json: resource
      else
        validation_error(resource)
      end
    end

  def validation_error(resource)
    render json: {
      errors: [
        {
          status: '400',
          title: 'Bad Request',
          detail: resource.errors,
          code: '100'
        }
      ]
    }, status: :bad_request
  end
end
