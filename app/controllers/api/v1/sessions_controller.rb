module Api
  module V1
    class SessionsController < ApiController
      skip_before_action :authenticate_request, only: [:create]

      COOKIE_OPTIONS = {
        httponly: true,
        secure: Rails.env.production?,
        same_site: Rails.env.production? ? :strict : :lax,
        domain: Rails.env.production? ? '.henslowescloud.com' : nil
      }.freeze

      # GET /auth/:provider/callback — OmniAuth posts here after Google OAuth
      def create
        auth = request.env['omniauth.auth']

        unless auth
          redirect_to "#{frontend_url}/auth/callback?error=oauth_failed", allow_other_host: true
          return
        end

        user = User.from_omniauth(auth)

        if user.persisted?
          token = JsonWebToken.encode(user_id: user.id)
          cookies[:auth_token] = COOKIE_OPTIONS.merge(value: token, expires: 24.hours.from_now)
          redirect_to "#{frontend_url}/auth/callback", allow_other_host: true
        else
          redirect_to "#{frontend_url}/auth/callback?error=user_not_found", allow_other_host: true
        end
      end

      # GET /api/v1/sessions/me — returns current user profile; authenticated via cookie
      def me
        render json: {
          id: current_user.id,
          email: current_user.email,
          first_name: current_user.first_name,
          last_name: current_user.last_name,
          role: current_user.role,
          subscription_status: current_user.subscription_status
        }
      end

      # DELETE /api/v1/sessions — clears the auth cookie
      def destroy
        cookies.delete(:auth_token, domain: Rails.env.production? ? '.henslowescloud.com' : nil)
        render json: { message: 'Logged out successfully' }, status: :ok
      end

      private

      def frontend_url
        ENV.fetch('FRONTEND_URL', 'http://localhost:5173')
      end
    end
  end
end
