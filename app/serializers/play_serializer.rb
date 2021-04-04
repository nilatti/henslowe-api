class PlaySerializer
  include JSONAPI::Serializer
  attributes :title, :date, :genre, :canonical, :text_notes, :synopsis, :original_line_count, :new_line_count
  
  # has_many :words

  # has_many :acts
  # attribute :acts do |play|
  #   ActSerializer.new(play.acts)
  # end
  # has_many :characters
  # belongs_to :author
  # belongs_to :production
end
