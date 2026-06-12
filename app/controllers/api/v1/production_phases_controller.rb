module Api
  module V1
    class ProductionPhasesController < ApiController
      before_action :set_production, only: [:index, :upsert]
      before_action :set_production_phase, only: [:update, :destroy]

      def index
        render json: @production.production_phases.as_json(include: :phase)
      end

      def upsert
        authorize! :update, @production
        results = production_phase_params.map do |pp|
          record = @production.production_phases.find_or_initialize_by(phase_id: pp[:phase_id])
          record.assign_attributes(start_date: pp[:start_date], end_date: pp[:end_date])
          record.save
          record
        end
        render json: results.as_json(include: :phase)
      end

      def destroy
        authorize! :update, @production
        @production_phase.destroy
        head :no_content
      end

      private

      def set_production
        @production = Production.find(params[:production_id])
      end

      def set_production_phase
        @production_phase = ProductionPhase.find(params[:id])
        @production = @production_phase.production
      end

      def production_phase_params
        params.require(:production_phases).map do |pp|
          pp.permit(:phase_id, :start_date, :end_date)
        end
      end
    end
  end
end
