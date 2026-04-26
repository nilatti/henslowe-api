module Api
  module V1
class LinesController < ApiController
  before_action :set_line, only: [:show, :update, :destroy]

  # GET /lines
  # GET /lines.json
  def index
    @lines = if params[:french_scene_id]
      Line.where(french_scene_id: params[:french_scene_id])
    else
      Line.all
    end
    render json: @lines
  end

  # GET /lines/1
  # GET /lines/1.json
  def show
    render json: @line
  end

  # POST /lines
  # POST /lines.json
  def create
    @line = Line.new(line_params)

    if @line.save
      render json: @line, status: :created
    else
      render json: @line.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /lines/1
  # PATCH/PUT /lines/1.json
  def update
    if @line.update(line_params)
      json_response(@line.as_json)
    else
      render json: @line.errors, status: :unprocessable_entity
    end
  end

  # DELETE /lines/1
  # DELETE /lines/1.json
  def destroy
    @line.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_line
      @line = Line.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def line_params
      params.require(:line).permit(
        :ana,
        :character_id,
        :character_group_id,
        :corresp,
        :french_scene_id,
        :kind,
        :next,
        :new_content,
        :new_line_count,
        :number,
        :original_content,
        :original_line_count,
        :prev,
        :xml_id,
        words_attributes: [:content, :kind, :order_number, :xml_id]
      )
    end
end
  end
end
