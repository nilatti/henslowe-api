module Api
  module V1
class TheatersController < ApiController
  # skip_before_action :doorkeeper_authorize!, only: %i[index show theater_names]
  before_action :set_theater, only: %i[show update destroy theater_skeleton]

  # GET /theaters
  def index
    @theaters = Theater.all

    json_response(@theaters.as_json(only: %i[
      id
      name
      city
      state
      zip
      phone_number
      website
      logo
      fake
      created_at
      updated_at
    ]))
  end

  # GET /theaters/1
  def show
    json_response(@theater.as_json(include:
      [
        :spaces,
        jobs: {
          include: [:character, :specialization, :user, production: {include: {play: { only: :title}}}]
        },
        productions: {
          include: :play
        }
      ]
    ))
  end

  # POST /theaters
  def create
    @theater = Theater.new(theater_params)
    if @theater.save
      specialization = Specialization.find_by(title: "Theater Admin")
      if specialization && current_user
        Job.create(theater_id: @theater.id, user_id: current_user.id, specialization_id: specialization.id)
      end
      json_response(@theater, :created)
    else
      render json: @theater.errors, status: :unprocessable_entity
    end
  end
  # PATCH/PUT /theaters/1
  def update
    @theater.update(theater_params)
    json_response(@theater.as_json(include: [:spaces, productions: {include: [:play]}]))
  end

  # DELETE /theaters/1
  def destroy
    theater = @theater
    Thread.new { theater.destroy }
    head :no_content
  end

  def theater_names
    @theaters = Theater.all
    render json: @theaters.as_json(only: %i[id fake name])
  end

  def theater_skeleton
    theater_staff = @theater.jobs.where(production_id: nil, user_id: User.select(:id))
    render json: @theater.as_json(
      only: %i[
        id name street_address city state zip
        phone_number mission_statement website
        calendar_url logo fake
      ],
      include: {
        spaces: {
          only: %i[id name seating_capacity city state]
        },
        productions: {
          only: %i[id start_date end_date],
          include: {
            play: {
              only: %i[id title]
            }
          }
        }
      }
    ).merge(
      'jobs' => theater_staff.as_json(
        only: %i[id specialization_id user_id],
        include: {
          specialization: { only: %i[id title] },
          user: { only: %i[id first_name last_name email] }
        }
      )
    )
  end

  private

  # Only allow a trusted parameter "white list" through.
  def theater_params
    params.require(:theater).permit(:calendar_url, :city, :id, :mission_statement, :name, :phone_number, :state, :street_address, :website, :zip, space_ids: [])
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_theater
    @theater = Theater.find(params[:id])
  end
end
  end
end
