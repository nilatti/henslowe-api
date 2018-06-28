require 'test_helper'

class AuthorsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @author = authors(:one)
  end

  test "should get index" do
    get authors_url, as: :json
    assert_response :success
  end

  test "should create author" do
    assert_difference('Author.count') do
      post authors_url, params: { author: { birthdate: @author.birthdate, deathdate: @author.deathdate, first_name: @author.first_name, gender: @author.gender, last_name: @author.last_name, middle_name: @author.middle_name, nationality: @author.nationality } }, as: :json
    end

    assert_response 201
  end

  test "should show author" do
    get author_url(@author), as: :json
    assert_response :success
  end

  test "should update author" do
    patch author_url(@author), params: { author: { birthdate: @author.birthdate, deathdate: @author.deathdate, first_name: @author.first_name, gender: @author.gender, last_name: @author.last_name, middle_name: @author.middle_name, nationality: @author.nationality } }, as: :json
    assert_response 200
  end

  test "should destroy author" do
    assert_difference('Author.count', -1) do
      delete author_url(@author), as: :json
    end

    assert_response 204
  end
end
