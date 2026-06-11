module Api
  module V1
class SpecializationsController < ApiController
  before_action :set_specialization, only: [:show, :update, :destroy]

  # GET /specializations
  def index
    @specializations = Specialization.all
    render json: @specializations.as_json(include: [:default_start_phase, :default_end_phase])
  end

  # GET /specializations/1
  def show
    json_response(@specialization.as_json(
      include: {
        default_start_phase: {},
        default_end_phase: {},
        jobs: {
          include: [
            character: { only: [:name, :xml_id] },
            production: { only: [play: { only: [:title] }] },
            theater: { only: [:id, :name] },
            user: { only: [:email, :fake, :first_name, :id, :last_name, :preferred_name, :program_name] }
          ]
        }
      }
    ))
  end

  # POST /specializations
  def create
    @specialization = Specialization.new(specialization_params)
    authorize! :create, @specialization

    if @specialization.save
      render json: @specialization, status: :created
    else
      render json: @specialization.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /specializations/1
  def update
    if @specialization.update(specialization_params)
      json_response(@specialization.as_json(include: [:default_start_phase, :default_end_phase]))
    else
      render json: @specialization.errors, status: :unprocessable_entity
    end
  end

  # DELETE /specializations/1
  def destroy
    @specialization.destroy
  end

  def specialization_names
    @specializations = Specialization.all
    render json: @specializations.as_json(only: %i[id name])
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_specialization
      @specialization = Specialization.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def specialization_params
      params.require(:specialization).permit(:default_end_phase_id, :default_start_phase_id, :description, :production_admin, :theater_admin, :title)
    end
end
  end
end
