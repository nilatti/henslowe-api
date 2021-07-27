module ApiHelper
  def authenticated_header(user)
    # application = FactoryBot.create(:application)
    user = FactoryBot.create(:user)
    application = create(:application)
    token = FactoryBot.create(:access_token, application: application, resource_owner_id: user.id)
    headers = { 'Accept': 'application/json', 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token.token }
  end
end
