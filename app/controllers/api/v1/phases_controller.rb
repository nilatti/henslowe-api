module Api
  module V1
    class PhasesController < ApiController
      before_action :set_phase, only: [:show, :update, :destroy]

      def index
        render json: Phase.all
      end

      def show
        render json: @phase
      end

      def create
        authorize! :create, Phase
        @phase = Phase.new(phase_params)
        if @phase.save
          render json: @phase, status: :created
        else
          render json: @phase.errors, status: :unprocessable_entity
        end
      end

      def update
        authorize! :update, @phase
        if @phase.update(phase_params)
          render json: @phase
        else
          render json: @phase.errors, status: :unprocessable_entity
        end
      end

      def destroy
        authorize! :destroy, @phase
        @phase.destroy
        head :no_content
      end

      private

      def set_phase
        @phase = Phase.find(params[:id])
      end

      def phase_params
        params.require(:phase).permit(:name, :position)
      end
    end
  end
end
