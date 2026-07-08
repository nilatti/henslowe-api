module Api
  module V1
class InvitationsController < ApiController
  skip_before_action :authenticate_request, only: [:show]
  before_action :set_invitation_by_token, only: [:show, :accept, :destroy]

  # GET /invitations?theater_id=&production_id=
  def index
    @invitations = Invitation.all
    @invitations = @invitations.where(theater_id: params[:theater_id]) if params[:theater_id]
    @invitations = @invitations.where(production_id: params[:production_id]) if params[:production_id]
    @invitations = @invitations.select { |invitation| current_ability.can?(:manage, invitation) }
    json_response(
      @invitations.as_json(include: [:specialization, :theater, :production, :invited_by])
    )
  end

  # GET /invitations/:token
  def show
    json_response(
      @invitation.as_json(
        only: [:email, :status, :payment_responsibility, :expires_at],
        include: {
          specialization: { only: [:id, :title] },
          theater: { only: [:id, :name] },
          production: { only: [:id, :start_date, :end_date] },
          invited_by: { only: [:id, :first_name, :last_name] }
        }
      )
    )
  end

  # POST /theaters/:theater_id/invitations
  # POST /productions/:production_id/invitations
  def create
    @invitation = Invitation.new(invitation_params)
    @invitation.invited_by_id = current_user.id
    @invitation.theater_id ||= params[:theater_id]
    @invitation.production_id ||= params[:production_id]
    authorize! :create, @invitation
    if @invitation.save
      InvitationMailer.invite(@invitation.id).deliver_later
      render json: @invitation.as_json(include: [:specialization, :theater, :production]), status: :created
    else
      render json: @invitation.errors, status: :unprocessable_entity
    end
  end

  # POST /invitations/:token/accept
  def accept
    authorize! :accept, @invitation

    if @invitation.expired?
      @invitation.update(status: :expired)
    end
    return render json: { base: ["invitation_no_longer_available"] }, status: :unprocessable_entity unless @invitation.pending?

    @job = Job.new(
      user_id: current_user.id,
      specialization_id: @invitation.specialization_id,
      theater_id: @invitation.theater_id,
      production_id: @invitation.production_id
    )

    if @job.save
      @invitation.update!(status: :accepted, accepted_at: Time.current, accepted_user_id: current_user.id)
      render json: @job.as_json(include: [:specialization, :theater, :production]), status: :created
    else
      render json: @job.errors, status: :unprocessable_entity
    end
  end

  # DELETE /invitations/:token
  def destroy
    authorize! :manage, @invitation
    @invitation.update(status: :revoked)
    head :no_content
  end

  private

  def set_invitation_by_token
    @invitation = Invitation.find_by!(token: params[:token])
  end

  def invitation_params
    params.require(:invitation).permit(:email, :specialization_id, :theater_id, :production_id, :payment_responsibility)
  end
end
  end
end
