class UpdateOnStages
  def initialize(character_id: nil, character_group_id: nil, user_id: nil)
    @character_id = character_id
    @character_group_id = character_group_id
    @user_id = user_id

    @importable_on_stages = []
  end
  def run
    update_user_for_characters(@character_id, @importable_on_stages, @user_id)
    update_user_for_character_groups(@character_group_id, @user_id)
    ActiveRecord::Base.connection_pool.with_connection do
      OnStage.import @importable_on_stages, on_duplicate_key_update: [:user_id, :updated_at]
    end
  end

  def update_user_for_characters(character_id, importable_on_stages, user_id)
    ActiveRecord::Base.connection_pool.with_connection do
      on_stages = OnStage.where(character_id: character_id)
      on_stages.each { |os| os.user_id = user_id; importable_on_stages << os }
    end
  end

  def update_user_for_character_groups(character_group_id, user_id)
  end
end
