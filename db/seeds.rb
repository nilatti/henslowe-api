# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
AdminUser.create!(email: 'admin@example.com', password: 'password', password_confirmation: 'password') if Rails.env.development?

webster = Author.create!(birthdate: '1580-01-01', deathdate: '1634-01-01', nationality: 'English', first_name: 'John', last_name: 'Webster', gender: 'male')
mandigo = Author.create!(birthdate: '1985-12-14', nationality: 'American', first_name: 'Pam', last_name: 'Mandigo', gender: 'female')
shakespeare = Author.create!(birthdate: '1564-04-23', deathdate: '1616-04-23', nationality: 'English', first_name: 'William', last_name: 'Shakespeare', gender: 'male')
webster.plays.create(title: 'The Duchess of Malfi', date: '1612-01-01', genre: ['tragedy'])
webster.plays.create(title: 'The White Devil', date: '1612-01-01', genre: ['tragedy'])
mandigo.plays.create(title: 'Washed', date: '2010-12-01', genre: ['tragedy'])
mandigo.plays.create(title: 'Give Us Good', date: '2012-08-01', genre: ['comedy'])
if Doorkeeper::Application.count.zero?
  Doorkeeper::Application.create(name: "React client", redirect_uri: "", scopes: "")
end
