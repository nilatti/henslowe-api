module ApiHelpers

  def json
    JSON.parse(response.body)
  end

  def login_with_api(user)
    puts "sign in called"
    puts user.email
    res = post '/api/sign_in', params: {
      user: {
        email: user.email,
        password: user.password
      }
    }
    puts res
  end

end
