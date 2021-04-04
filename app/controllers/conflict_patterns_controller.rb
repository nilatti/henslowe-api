class ConflictPatternsController < ApiController
  before_action :set_conflict_pattern, only: [:show, :update, :destroy]

  def index
    if (params[:user_id])
      @conflict_patterns = ConflictPattern.where(user_id: params[:user_id])
    elsif (params[:space_id])
      @conflict_patterns = ConflictPattern.where(space_id: params[:space_id])
    end

    render json: @conflict_patterns.as_json
  end

  # GET /conflicts/1
  # GET /conflicts/1.json
  def show
    render json: @conflict_pattern.as_json
  end

  # POST /conflicts
  # POST /conflicts.json
  def create
    @conflict_pattern = ConflictPattern.new(conflict_pattern_params)

    if @conflict_pattern.save
      render json: @conflict_pattern, status: :created, location: @user
    else
      render json: @conflict_pattern.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /conflicts/1
  # PATCH/PUT /conflicts/1.json
  def update
    if @conflict_pattern.update(conflict_pattern_params)
      render json: @conflict_pattern
    else
      render json: @conflict_pattern.errors, status: :unprocessable_entity
    end
  end

  # DELETE /conflicts/1
  # DELETE /conflicts/1.json
  def destroy
    @conflict_pattern.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_conflict_pattern
      @conflict_pattern = ConflictPattern.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def conflict_pattern_params
      params.require(:conflict_pattern).permit(
        :category,
        :days_of_week,
        :end_date,
        :end_time,
        :start_date,
        :start_time,
        :space_id,
        :user_id
      )
    end
end
