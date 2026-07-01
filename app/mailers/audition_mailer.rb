class AuditionMailer < ApplicationMailer
  def new_submission(job_id)
    @job = Job.includes(:user, production: [:play, :theater]).find(job_id)
    @production = @job.production
    @auditioner = @job.user

    admins = User.joins(jobs: :specialization)
      .where(jobs: { production_id: @production.id })
      .where(specializations: { production_admin: true })
      .reorder(nil)
      .distinct

    recipient_emails = admins.pluck(:email)
    return if recipient_emails.empty?

    mail(
      to: recipient_emails,
      subject: "New audition submission — #{@production.play&.title || 'Production'}"
    )
  end
end
