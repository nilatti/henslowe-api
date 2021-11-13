class SpecializationsController < ApiController
  before_action :set_specialization, only: [:show, :update, :destroy]

  # GET /specializations
  def index
    @specializations = Specialization.all

    render json: @specializations
  end

  # GET /specializations/1
  def show
    json_response(@specialization.as_json(
      include:{
        jobs: {
          include: [
            character: {
              only: [
                :name,
                :xml_id
              ]
            },
            production: {
              only: [
                play: {
                  only: [
                    :title
                  ]
                }
              ]
            },
            theater: {
              only: [
                :id,
                :name
              ]
            },
            user: {
              only: [
                :email,
                :fake,
                :first_name,
                :id,
                :last_name,
                :preferred_name,
                :program_name
              ]
            }
          ]
        }}
    ))
  end

  # POST /specializations
  def create
    @specialization = Specialization.new(specialization_params)

    if @specialization.save
      render json: @specialization, status: :created, location: @specialization
    else
      render json: @specialization.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /specializations/1
  def update
    if @specialization.update(specialization_params)
      json_response(@specialization.as_json)
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
      params.require(:specialization).permit(:description, :title)
    end
end
