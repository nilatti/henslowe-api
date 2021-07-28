class UsersController < ApiController
  before_action :set_user, only: %i[show update destroy]
  skip_before_action :doorkeeper_authorize!, only: %i[create]

  # GET /Users
  def index
    @users = User.all

    json_response(@users)
  end

  # GET /Users/1
  def show
    json_response(@user.as_json(include: [:conflicts, :conflict_patterns, :jobs]))
  end

  def create
      user = User.new(email: user_params[:email], password: user_params[:password])

      client_app = Doorkeeper::Application.find_by(uid: params[:client_id])

      return render(json: { error: 'Invalid client ID'}, status: 403) unless client_app

      if user.save
        # create access token for the user, so the user won't need to login again after registration
        access_token = Doorkeeper::AccessToken.create(
          resource_owner_id: user.id,
          application_id: client_app.id,
          refresh_token: generate_refresh_token,
          expires_in: Doorkeeper.configuration.access_token_expires_in.to_i,
          scopes: ''
        )

        # return json containing access token and refresh token
        # so that user won't need to call login API right after registration
        render(json: {
          user: {
            id: user.id,
            email: user.email,
            access_token: access_token.token,
            token_type: 'bearer',
            expires_in: access_token.expires_in,
            refresh_token: access_token.refresh_token,
            created_at: access_token.created_at.to_time.to_i
          }
        })
      else
        render(json: { error: user.errors.full_messages }, status: 422)
      end
    end

  def update
    @user.update(user_params)
    json_response(@user)
  end

  def destroy
    @user.destroy
    head :no_content
  end

  def build_conflict_schedule
    puts "build conflict schedule called"
    puts params[:conflict_schedule_pattern]
    set_user
    conflict_schedule_pattern = params[:conflict_schedule_pattern]
    puts conflict_schedule_pattern  
    end_date = conflict_schedule_pattern[:end_date] || Date.today + 1.year
    start_date = conflict_schedule_pattern[:start_date] || Date.today
    conflict_pattern = ConflictPattern.create(
      category: conflict_schedule_pattern[:category],
      days_of_week: conflict_schedule_pattern[:days_of_week],
      end_date: end_date,
      end_time: conflict_schedule_pattern[:end_time],
      start_date: start_date,
      start_time: conflict_schedule_pattern[:start_time],
      user: @user
    )

    #order matters here, Sidekiq does not accept keyword args
    BuildConflictsScheduleWorker.perform_async(
      conflict_schedule_pattern[:category],
      conflict_pattern.id,
      conflict_schedule_pattern[:days_of_week],
      end_date,
      conflict_schedule_pattern[:end_time],
      nil,
      start_date,
      conflict_schedule_pattern[:start_time],
      @user.id
    )
      json_response(@user.as_json(include: [:conflicts, :conflict_patterns, :jobs]))
  end

  private

  private

    def user_params
      params.permit(:email, :password)
    end

    def generate_refresh_token
      loop do
        # generate a random token string and return it,
        # unless there is already another token with the same string
        token = SecureRandom.hex(32)
        break token unless Doorkeeper::AccessToken.exists?(refresh_token: token)
      end
    end

  # Only allow a trusted parameter "white list" through.
  def user_params
    params.require(:user).permit(
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
    )
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_user
    @user = User.find(params[:id])
  end
end
