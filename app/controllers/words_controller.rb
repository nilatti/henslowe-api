class WordsController < ApiController
  before_action :set_word, only: [:show, :update, :destroy]
  before_action :set_play
  # GET /words
  def index
    if @play
      @words = Word.where(play_id: @play.id)
    else
      @words = Word.all
    end

    render json: @words.as_json
  end

  # GET /words/1
  def show
    render json: @word.as_json
  end

  # POST /words
  def create
    @word = Word.new(word_params)

    if @word.save
      render json: @word, status: :created, location: @play
    else
      render json: @word.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /words/1
  def update
    if @word.update(word_params)
      render json: @word
    else
      render json: @word.errors, status: :unprocessable_entity
    end
  end

  # DELETE /words/1
  def destroy
    @word.destroy
  end


  private
    # Use callbacks to share common setup or constraints between wordions.
    def set_play
      if params[:play_id]
        @play = Play.find(params[:play_id])
      end
    end

    def set_word
      @word = Word.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def word_params
      params.require(:word).permit(:content, :kind, :xml_id, :line_id, :line_number, :play_id)
    end
end
