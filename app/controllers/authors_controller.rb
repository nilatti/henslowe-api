class AuthorsController < ApiController
  before_action :set_author, only: %i[show update destroy]

  # GET /authors
  def index
    @authors = Author.all

    json_response(@authors)
  end

  # GET /authors/1
  def show
    json_response(@author.as_json(include: [:plays]))
  end

  # POST /authors
  def create
    @author = Author.create!(author_params)
    json_response(@author, :created)
  end

  # PATCH/PUT /authors/1
  def update
    @author.update(author_params)
    json_response(@author.as_json(include: [:plays]))

    # in example returned no content, but I don't think this is the desired behavior so I changed it.
  end

  # DELETE /authors/1
  def destroy
    @author.destroy
    head :no_content
  end

  def author_names
    @authors = Author.all
    render json: @authors.as_json(only: %i[id first_name last_name])
  end

  private

  # Only allow a trusted parameter "white list" through.
  def author_params
    params.require(:author).permit(:birthdate, :deathdate, :nationality, :first_name, :middle_name, :last_name, :gender, :id)
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_author
    @author = Author.find(params[:id])
  end
end
