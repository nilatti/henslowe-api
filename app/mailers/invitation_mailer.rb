class InvitationMailer < ApplicationMailer
  def invite(invitation_id)
    @invitation = Invitation.includes(:specialization, :theater, :production, :invited_by).find(invitation_id)
    @org_name = @invitation.theater&.name || @invitation.production&.theater&.name
    @accept_url = "#{ENV.fetch('FRONTEND_URL', 'https://henslowescloud.com')}/invitations/#{@invitation.token}"

    mail(
      to: @invitation.email,
      subject: "You've been invited to join #{@org_name} on Henslowe"
    )
  end
end
