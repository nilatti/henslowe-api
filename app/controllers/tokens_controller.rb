class TokensController < Doorkeeper::TokensController
      before_action :doorkeeper_authorize!, only: [:logout]

      def login
        user = User.find_for_database_authentication(email: params[:email])

        case
        when user.nil? || !user.valid_password?(params[:password])
          response_code = 'devise.failure.invalid'
          render json: {
            response_code: response_code,
            response_message: I18n.t(response_code)
          }, status: 400
        when user&.inactive_message == :unconfirmed
          response_code = 'devise.failure.unconfirmed'
          render json: {
            response_code: response_code,
            response_message: I18n.t(response_code)
          }, status: 400
        when !user.active_for_authentication?
          create
        else
          create
        end
      end

      def refresh
        create
      end

      def logout
        # Follow doorkeeper-5.1.0 revoke method, different from the latest code on the repo on 6 Sept 2019

        params[:token] = access_token

        revoke_token if authorized?
        response_code = 'custom.success.default'
        render json: {
          response_code: response_code,
          response_message: I18n.t(response_code)
        }, status: 200
      end

      private

      def access_token
        pattern = /^Bearer /
        header = request.headers['Authorization']
        header.gsub(pattern, '') if header && header.match(pattern)
      end
    end
