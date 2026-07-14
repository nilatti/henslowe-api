module Api
  module V1
class DepartmentsController < ApiController
  before_action :set_department, only: [:show, :update, :destroy]

  # GET /departments
  def index
    @departments = Department.all
    render json: @departments
  end

  # GET /departments/1
  def show
    json_response(@department.as_json(include: :specializations))
  end

  # POST /departments
  def create
    @department = Department.new(department_params)
    authorize! :create, @department

    if @department.save
      render json: @department, status: :created
    else
      render json: @department.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /departments/1
  def update
    authorize! :update, @department
    if @department.update(department_params)
      json_response(@department)
    else
      render json: @department.errors, status: :unprocessable_entity
    end
  end

  # DELETE /departments/1
  def destroy
    authorize! :destroy, @department
    @department.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_department
      @department = Department.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def department_params
      params.require(:department).permit(:name, :description)
    end
end
  end
end
