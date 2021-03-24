class ActSerializer
    include JSONAPI::Serializer
    attributes :number, :summary, :start_page, :end_page, :heading, :original_line_count, :new_line_count, :rehearsals
    belongs_to :play
    has_many :scenes
    has_many :french_scenes
    has_many :lines
    has_many :on_stages

    # attribute :scenes do |act|
    #   SceneSerializer.new(act.scenes)
    # end
  end

    