class SessionsController < Devise::SessionsController

  respond_to :json
  # def create
  #   self.resource = warden.authenticate!(auth_options)
  #   set_flash_message(:notice, :signed_in) if is_flashing_format?
  #   sign_in(resource_name, resource)
  #   respond_with(resource) do |format|
  #     format.json { render json: {redirect_url: after_sign_in_path_for(resource)}, status: 200 }
  #   end
  # end
 private
 #
 def respond_with(resource, _opts = {})
   render json: resource
 end

 def respond_to_on_destroy
   head :no_content
 end
end
