module Api
  module V1
class RehearsalsController < ApiController
  before_action :set_rehearsal, only: [:show, :update, :destroy]
  before_action :set_parent
  # GET /acts
  def index
    @rehearsals = @parent.rehearsals
    render json: @rehearsals.as_json(include: [:users, space: {only: [:id, :name]}, acts: {include: :scenes, methods: [:find_on_stages]},  french_scenes: {methods: [:pretty_name, :find_on_stages], include: {scene: {only: [:id, :act_id]}}}, scenes: {methods: [:pretty_name, :find_on_stages]}])
  end

  # GET /acts/1
  def show
    render json: @rehearsal.as_json(include: [:acts, :users, french_scenes: {methods: :pretty_name, include: {scene: {only: [:id, :act_id]}}}, scenes: {methods: :pretty_name}])
  end

  # POST /acts
  def create
    @rehearsal = Rehearsal.new(rehearsal_params)
    if @rehearsal.save
      apply_production_defaults(@rehearsal)
      @rehearsal.sync_conflicts
      json_response(@rehearsal.as_json(include: [:users, space: {only: [:id, :name]}, acts: {include: :scenes, methods: [:find_on_stages]},  french_scenes: {methods: [:pretty_name, :find_on_stages], include: {scene: {only: [:id, :act_id]}}}, scenes: {methods: [:pretty_name, :find_on_stages]}]))
    else
      render json: @rehearsal.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /acts/1
  def update
    @rehearsal.update(rehearsal_params)
    @rehearsal.sync_conflicts
    json_response(@rehearsal.as_json(include: [:users, space: {only: [:id, :name]}, acts: {include: :scenes, methods: [:find_on_stages]},  french_scenes: {methods: [:pretty_name, :find_on_stages], include: {scene: {only: [:id, :act_id]}}}, scenes: {methods: [:pretty_name, :find_on_stages]}]))
  end

  # DELETE /acts/1
  def destroy
    send_deletion_cancellations(@rehearsal)
    @rehearsal.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_parent
      if params[:production_id]
        @parent = Production.find(params[:production_id])
        @parent_type = 'production'
      elsif params[:act_id]
        @parent = Act.find(params[:act_id])
        @parent_type = 'act'
      elsif params[:scene_id]
        @parent = Scene.find(params[:scene_id])
        @parent_type = 'scene'
      elsif params[:french_scene_id]
        @parent = FrenchScene.find(params[:french_scene_id])
        @parent_type = 'french_scene'
      end
    end

    def set_rehearsal
      @rehearsal = Rehearsal.includes(:acts, :french_scenes, :scenes).find(params[:id])
    end

    # The rehearsal_invites rows (and the rehearsal itself) are gone by the time a
    # deliver_later job runs, so the cancellation ICS is built from a plain snapshot
    # hash rather than re-fetching the rehearsal by id.
    def send_deletion_cancellations(rehearsal)
      invited_user_ids = rehearsal.rehearsal_invites.pluck(:user_id)
      return if invited_user_ids.empty?

      snapshot = {
        uid: "rehearsal-#{rehearsal.id}@henslowescloud.com",
        sequence: rehearsal.ics_sequence + 1,
        summary: rehearsal.calendar_summary,
        description: rehearsal.calendar_description,
        location: rehearsal.calendar_location,
        start_time: rehearsal.start_time,
        end_time: rehearsal.end_time,
      }
      invited_user_ids.each do |user_id|
        RehearsalCalendarMailer.cancel_deleted(snapshot, user_id).deliver_later
      end
    end

    def apply_production_defaults(rehearsal)
      production = rehearsal.production
      return unless production

      if rehearsal.space_id.nil? && production.default_space_id.present?
        rehearsal.update_column(:space_id, production.default_space_id)
      end

      default_user_ids = production.default_call_users.pluck(:id)
      if default_user_ids.any?
        existing_ids = rehearsal.user_ids
        rehearsal.user_ids = (existing_ids + default_user_ids).uniq
      end
    end

    # Only allow a trusted parameter "white list" through.
    def rehearsal_params
      params.require(:rehearsal).permit(
        :end_time,
        :notes,
        :production_id,
        :space_id,
        :start_time,
        :text_unit,
        :title,
        act_ids: [],
        french_scene_ids: [],
        scene_ids: [],
        user_ids: [],
      )
    end
end
  end
end
