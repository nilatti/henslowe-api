module Api
  module V1
class LabelsController < ApiController
  before_action :set_label, only: [:show, :update, :destroy]

  # GET /labels
  # GET /labels.json
  def index
    @labels = Label.all
  end

  # GET /labels/1
  # GET /labels/1.json
  def show
    render json: @label
  end

  # POST /labels
  # POST /labels.json
  def create
    @label = Label.new(label_params)

    if @label.save
      render json: @label, status: :created
    else
      render json: @label.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /labels/1
  # PATCH/PUT /labels/1.json
  def update
    if @label.update(label_params)
      render json: @label, status: :ok
    else
      render json: @label.errors, status: :unprocessable_entity
    end
  end

  # DELETE /labels/1
  # DELETE /labels/1.json
  def destroy
    @label.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_label
      @label = Label.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def label_params
      params.require(:label).permit(:xml_id, :line_number, :content, :french_scene_id)
    end
end
  end
end
