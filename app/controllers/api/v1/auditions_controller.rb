module Api
  module V1
    class AuditionsController < ApiController
      def create
        production = Production.find(params[:production_id])
        specialization = Specialization.find_by!(title: 'Auditioner')

        job = Job.find_or_create_by!(
          production: production,
          user: current_user,
          specialization: specialization
        )

        if submission_params.any?
          submission = job.audition_submission || job.build_audition_submission
          submission.update!(submission_params)
        end

        render json: job.as_json(include: [:specialization, audition_submission: { only: [:id, :video_url, :notes] }]), status: :created
      rescue ActiveRecord::RecordNotFound => e
        render json: { error: e.message }, status: :not_found
      end

      private

      def submission_params
        params.fetch(:audition_submission, {}).permit(:video_url, :notes).to_h.reject { |_, v| v.blank? }
      end
    end
  end
end
