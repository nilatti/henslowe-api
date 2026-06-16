module Api
  module V1
    class OpenAuditionsController < ApiController
      skip_before_action :authenticate_request

      def index
        phases = ProductionPhase
          .includes(production: [:play, :theater, :production_phases])
          .where(phase_id: PhaseIds::AUDITIONS)
          .where('production_phases.start_date <= ? AND production_phases.end_date >= ?', Date.today, Date.today)

        render json: phases.map { |pp|
          production_phases = pp.production.production_phases
          rehearsal = production_phases.find { |p| p.phase_id == PhaseIds::REHEARSAL }
          run = production_phases.find { |p| p.phase_id == PhaseIds::RUN }
          {
            production_id: pp.production_id,
            play_title: pp.production.play&.title,
            theater_name: pp.production.theater&.name,
            theater_city: pp.production.theater&.city,
            theater_state: pp.production.theater&.state,
            audition_start_date: pp.start_date,
            audition_end_date: pp.end_date,
            rehearsal_start_date: rehearsal&.start_date,
            run_end_date: run&.end_date,
          }
        }
      end
    end
  end
end
