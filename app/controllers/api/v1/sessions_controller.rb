module Api
  module V1
    class SessionsController < ApiController
      skip_before_action :authenticate_request, only: [:create]

      # POST /auth/:provider/callback
      # This is called by OmniAuth after Google OAuth succeeds
      def create
        auth = request.env['omniauth.auth']

        unless auth
          render json: { error: 'OAuth authentication failed' }, status: :unauthorized
          return
        end

        user = User.from_omniauth(auth)

        if user.persisted?
          token = JsonWebToken.encode(user_id: user.id)
          render json: {
            token: token,
            user: {
              id: user.id,
              email: user.email,
              first_name: user.first_name,
              last_name: user.last_name,
              role: user.role
            }
          }, status: :ok
        else
          render json: {
            error: 'Could not create or find user',
            details: user.errors.full_messages
          }, status: :unprocessable_entity
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
