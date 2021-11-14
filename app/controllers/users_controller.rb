class UsersController < ApiController
  # load_and_authorize_resource
  before_action :set_user, only: %i[show update destroy]

  # GET /Users
  def index
    @users = User.all
    json_response(@users)
  end

  # GET /Users/1
  def show
    if current_user && @user
      overlap = current_user.jobs_overlap(@user)
      if overlap == "none"
        json_response(@user.as_json(only: [
            :bio,
            :city,
            :description,
            :email,
            :first_name,
            :gender,
            :id,
            :last_name,
            :preferred_name,
            :program_name,
            :state,
            :website
          ]))
      elsif overlap == "past peer"
        json_response(@user.as_json(only: [
            :bio,
            :city,
            :description,
            :email,
            :first_name,
            :gender,
            :id,
            :last_name,
            :preferred_name,
            :program_name,
            :state,
            :website
          ],
          include: :jobs
        ))
      elsif overlap == "theater peer"
        json_response(@user.as_json(only: [
            :bio,
            :city,
            :description,
            :email,
            :first_name,
            :gender,
            :id,
            :last_name,
            :phone_number,
            :preferred_name,
            :program_name,
            :state,
            :street_address,
            :website,
            :zip
          ],
          include: [:conflicts, :conflict_patterns, :jobs]
        ))
      elsif overlap == "production peer"
        json_response(@user.as_json(only: [
            :bio,
            :city,
            :description,
            :email,
            :emergency_contact_name,
            :emergency_contact_number,
            :first_name,
            :gender,
            :id,
            :last_name,
            :phone_number,
            :preferred_name,
            :program_name,
            :state,
            :street_address,
            :timezone,
            :website,
            :zip
          ],
          include: [:jobs, :conflicts, :conflict_patterns]
        ))
      elsif overlap == "superadmin" || overlap == "self" ||overlap == "theater admin" || overlap == "production admin"
        json_response(@user.as_json(include:
          [
            :conflicts,
            :conflict_patterns,
            jobs: {
              include: [
                character: {
                  only: :name
                },
                character_group: {
                  only: :name
                },
                production: {
                  include: {
                    play: {
                      only: [
                        :id,
                        :title
                        ]
                      }
                    }
                  },
                specialization: {
                  only: :title
                },
                theater: {
                  only: :name
                }
              ]
            },
            rehearsals: {
              include: [
                :acts,
                :users,
                french_scenes: {
                  methods:
                  :pretty_name
                },
                scenes: {
                  methods:
                  :pretty_name
                }
              ]
            }
          ]
        ))
      end
    else
      return head :forbidden
    end
  end

  def create
    @user = User.create!(user_params)
    json_response(@user, :created)
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
    set_user
    conflict_schedule_pattern = params[:conflict_schedule_pattern]
    end_date = conflict_schedule_pattern[:end_date] || Date.today + 1.year
    start_date = conflict_schedule_pattern[:start_date] || Date.today
    conflict_pattern = ConflictPattern.create(
      category: conflict_schedule_pattern[:category],
      days_of_week: conflict_schedule_pattern[:days_of_week],
      end_date: end_date,
      end_time: conflict_schedule_pattern[:end_time],
      space_id: conflict_schedule_pattern[:space_id],
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
      conflict_schedule_pattern[:space_id],
      start_date,
      conflict_schedule_pattern[:start_time],
      @user.id
    )
      json_response(@user.as_json(include: [:conflicts, :conflict_patterns, :jobs]))
  end

  def fake
    @users = User.where(fake: true)
    json_response(@users.as_json(include: :jobs))
  end

  private

    def user_params
      params.permit(:email, :password)
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
