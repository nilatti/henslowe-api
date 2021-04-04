class SpacesController < ApiController
  before_action :set_space, only: [:show, :update, :destroy]

  # GET /spaces
  def index
    @spaces = Space.all

    render json: @spaces
  end

  # GET /spaces/1
  def show
    json_response(@space.as_json(include: [:conflicts, :conflict_patterns, :theaters]))
  end

  # POST /spaces
  def create
    @space = Space.new(space_params)

    if @space.save
      render json: @space, status: :created, location: @space
    else
      render json: @space.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /spaces/1
  def update
    if @space.update(space_params)
      json_response(@space.as_json(include: [:conflicts, :conflict_patterns, :theaters]))
    else
      render json: @space.errors, status: :unprocessable_entity
    end
  end

  # DELETE /spaces/1
  def destroy
    @space.destroy
  end

  def space_names
    @spaces = Space.all
    render json: @spaces.as_json(only: %i[id name])
  end

  def build_conflict_schedule
    set_space
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
      space: @space
    )

    #order matters here, Sidekiq does not accept keyword args
    BuildConflictsScheduleWorker.perform_async(
      conflict_schedule_pattern[:category],
      conflict_pattern.id,
      conflict_schedule_pattern[:days_of_week],
      end_date,
      conflict_schedule_pattern[:end_time],
      @space.id,
      start_date,
      conflict_schedule_pattern[:start_time]
    )
      json_response(@space.as_json(include: [:conflicts, :conflict_patterns, :theaters]))
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_space
      @space = Space.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def space_params
      params.require(:space).permit(:name, :street_address, :city, :state, :zip, :phone_number, :mission_statement, :website, :seating_capacity, theater_ids: [])
    end
end
