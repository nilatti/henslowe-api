class TheatersController < ApiController
  # skip_before_action :doorkeeper_authorize!, only: %i[index show theater_names]
  before_action :set_theater, only: %i[show update destroy]

  # GET /theaters
  def index
    @theaters = Theater.all

    json_response(@theaters)
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
    @theater = Theater.create!(theater_params)
    if @theater
      @specialization = Specialization.find_by(title: "Theater Admin")
      Job.create(theater_id: @theater.id, user_id: current_user.id, specialization_id: @specialization.id)
    end
    json_response(@theater, :created)
  end
  # PATCH/PUT /theaters/1
  def update
    @theater.update(theater_params)
    json_response(@theater.as_json(include: [:spaces, productions: {include: [:play]}]))
  end

  # DELETE /theaters/1
  def destroy
    @theater.destroy
    head :no_content
  end

  def theater_names
    @theaters = Theater.all
    render json: @theaters.as_json(only: %i[id fake name])
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
