class UpdateOnStagesWorker
  include SuckerPunch::Job

  def perform(character_id, character_group_id, user_id)
    UpdateOnStages.new(character_id: character_id, character_group_id: character_group_id, user_id: user_id).run
  end
end
