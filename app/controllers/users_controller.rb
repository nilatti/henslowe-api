class UsersController < ApiController
  before_action :set_user, only: %i[show update destroy]

  # GET /Users
  def index
    @users = User.all

    json_response(@users)
  end

  # GET /Users/1
  def show
    json_response(@user.as_json(include: [:conflicts, :jobs]))
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
    json_response(@user.as_json)
    conflict_schedule_pattern = params[:user][:conflict_schedule_pattern]
    puts(conflict_schedule_pattern)
    # BuildConflictScheduleWorker.perform_async(
    #   rehearsal_schedule_pattern[:days_of_week],
    #   rehearsal_schedule_pattern[:end_time],
    #   rehearsal_schedule_pattern[:time_between_breaks],
    #   rehearsal_schedule_pattern[:start_time],
    #   @user.id
    # )
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
