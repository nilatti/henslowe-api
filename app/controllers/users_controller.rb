class UsersController < ApiController
  before_action :set_user, only: %i[show update destroy]

  # GET /Users
  def index
    @users = User.all

    json_response(@users)
  end

  # GET /Users/1
  def show
    json_response(@user.as_json(include: [:conflicts, :conflict_patterns, :jobs]))
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
    set_user
    conflict_schedule_pattern = params[:conflict_schedule_pattern]
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
