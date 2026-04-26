module Api
  module V1
class JobsController < ApiController
  before_action :set_job, only: [:show, :update, :destroy]

  # GET /jobs
  def index
    @jobs = Job.all
    @jobs = @jobs.where(production_id: params[:production_id]) if params[:production_id]
    @jobs = @jobs.where(theater_id: params[:theater_id]) if params[:theater_id]
    @jobs = @jobs.where(user_id: params[:user_id]) if params[:user_id]
    if params[:roles]
      roles = params[:roles].split(',')
      specialization_ids = Specialization.where(title: roles).pluck(:id)
      @jobs = @jobs.where(specialization_id: specialization_ids)
    end
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
            include: [:conflicts, :jobs]
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
    if job_params['character_id'] || job_params['character_group_id']
      UpdateOnStagesWorker.perform_async(job_params['character_id'], job_params['character_group_id'], job_params['user_id'])
    end
    if @job.save
      render json:@job.as_json(
        include: [
          :character,
          :specialization,
          :theater,
          :user,
          production: {
            include: {play: { only: [:title]}}
          }
        ]
      ), status: :created
    else
      render json: @job.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /jobs/1
  def update
    if job_params['character_id'] || job_params['character_group_id']
      UpdateOnStagesWorker.perform_async(job_params['character_id'], job_params['character_group_id'], job_params['user_id'])
    end
    if @job.update(job_params)
      json_response(
        @job.as_json(
          include: [
            :character,
            :specialization,
            :theater,
            user: {
              include: [:conflicts, :jobs]
            },
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
  end
end
