module Api
  module V1
    class SessionsController < ApiController
      skip_before_action :authenticate_request, only: [:create]

      # POST /auth/:provider/callback
      # This is called by OmniAuth after Google OAuth succeeds
      def create
        auth = request.env['omniauth.auth']

        unless auth
          redirect_to "#{ENV.fetch('FRONTEND_URL', 'http://localhost:5173')}/auth/callback?error=oauth_failed", allow_other_host: true
          return
        end

        user = User.from_omniauth(auth)

        if user.persisted?
          token = JsonWebToken.encode(user_id: user.id)
          user_params = {
            id: user.id,
            email: user.email,
            first_name: user.first_name,
            last_name: user.last_name,
            role: user.role,
            subscription_status: user.subscription_status
          }.to_query

          redirect_to "#{ENV.fetch('FRONTEND_URL', 'http://localhost:5173')}/auth/callback?token=#{token}&#{user_params}", allow_other_host: true
        else
          redirect_to "#{ENV.fetch('FRONTEND_URL', 'http://localhost:5173')}/auth/callback?error=user_not_found&details=#{user.errors.full_messages.join(',')}", allow_other_host: true
        end
      end

      # DELETE /api/v1/sessions
      # JWT is stateless — logout is handled client-side by discarding the token
      def destroy
        render json: { message: 'Logged out successfully' }, status: :ok
      end
    end
  end
end
