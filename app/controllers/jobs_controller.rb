class JobsController < ApiController
  before_action :set_job, only: [:show, :update, :destroy]

  # GET /jobs
  def index
    @jobs = Job.filter(params.slice(:production, :specialization, :theater, :user))

    json_response(
      @jobs.as_json(
        include: [
          :specialization,
          :theater,
          :character,
          production: {
            include: {play: { only: [:title]}}
          },
          user: {
            include: :conflicts
          }
        ]
      )
    )
  end

  # GET /jobs/1
  def show
    json_response(
      @job.as_json(
        include: [
          :character,
          :specialization,
          :theater,
          :user,
          production: {
            include: {play: { only: [:title]}}
          }
        ]
      )
    )
  end

  # POST /jobs
  def create
    @job = Job.new(job_params)

    if @job.save
      render json: @job, status: :created, location: @job
    else
      render json: @job.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /jobs/1
  def update
    if @job.update(job_params)
      json_response(
        @job.as_json(
          include: [
            :character,
            :specialization,
            :theater,
            :user,
            production: {
              include: :play
            }
          ]
        )
      )
    else
      render json: @job.errors, status: :unprocessable_entity
    end
  end

  # DELETE /jobs/1
  def destroy
    @job.destroy
  end

  def get_actors_for_production
    @jobs = Job.actor_for_production(params[:production])
    json_response(
      @jobs.as_json(
        include: [
          user: {
            only: [
              :first_name,
              :last_name,
              :preferred_name
            ]
          },
        ]
      )
    )
  end

  def get_actors_and_auditioners_for_production
    @jobs = Job.actor_or_auditioner_for_production(params[:production])
    json_response(
      @jobs.as_json(
        include: [
          user: {
            only: [
              :first_name,
              :last_name,
              :preferred_name
            ]
          },
        ]
      )
    )
  end

  def get_actors_and_auditioners_for_theater
    @jobs = Job.actor_or_auditioner_for_theater(params[:theater])
    json_response(
      @jobs.as_json(
        include: [
          user: {
            only: [
              :first_name,
              :last_name,
              :preferred_name
            ]
          },
        ]
      )
    )
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_job
      @job = Job.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def job_params
      params.require(:job).permit(:character_id, :end_date, :id, :production_id, :specialization_id, :start_date, :theater_id, :user_id)
    end
end
