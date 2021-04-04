class FrenchSceneSerializer
    include JSONAPI::Serializer
    attributes :number, :summary, :start_page, :end_page, :original_line_count, :new_line_count, :rehearsals
    belongs_to :scene
    has_many :entrance_exits
    has_many :lines
    has_many :sound_cues
    has_many :on_stages
    has_many :characters
    has_many :character_groups
    has_many :users
    has_many :stage_directions
    attribute :lines do |french_scene|
      LineSerializer.new(french_scene.lines)
    end
  end

  