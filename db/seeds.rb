phases = [
  'Preproduction',
  'Auditions',
  'Rehearsal',
  'Technical Rehearsal',
  'Run',
  'Postproduction',
]

phases.each_with_index do |name, i|
  Phase.find_or_create_by!(name: name) do |p|
    p.position = i + 1
  end
end

puts "Phases seeded: #{Phase.count}"

specializations = [
  { title: 'Director',                context: :production },
  { title: 'Actor',                   context: :production },
  { title: 'Auditioner',              context: :production },
  { title: 'Music Director',          context: :production },
  { title: 'Fight Director',          context: :production },
  { title: 'Costume Designer',        context: :production },
  { title: 'Set Designer',            context: :production },
  { title: 'Lighting Designer',       context: :production },
  { title: 'Sound Designer',          context: :production },
  { title: 'Stage Manager',           context: :production },
  { title: 'Playwright',              context: :production },
  { title: 'Technical Director',      context: :production },
  { title: 'Lighting Board Operator', context: :production },
  { title: 'Sound Board Operator',    context: :production },
  { title: 'Assistant Stage Manager', context: :production },
  { title: 'Props Designer',          context: :production },
  { title: 'Production Admin',        context: :production },
  { title: 'Executive Director',      context: :theater },
  { title: 'Artistic Director',       context: :theater },
  { title: 'Director of Education',   context: :theater },
  { title: 'Director of Marketing',   context: :theater },
  { title: 'House Manager',           context: :theater },
  { title: 'Usher',                   context: :theater },
  { title: 'Theater Admin',           context: :theater },
  { title: 'Producer',                context: :both },
]

specializations.each do |attrs|
  Specialization.find_or_create_by!(title: attrs[:title]) do |s|
    s.context = attrs[:context]
  end
end

puts "Specializations seeded: #{Specialization.count}"

authors = [
  { first_name: 'William', last_name: 'Shakespeare', birthdate: '1564', deathdate: '1616' },
  { first_name: '',        last_name: 'Sophocles',   birthdate: 'c. 497 BC', deathdate: '406 BC' },
  { first_name: 'Anton',   last_name: 'Chekhov',     birthdate: '1860', deathdate: '1904' },
  { first_name: 'Tennessee', last_name: 'Williams',  birthdate: '1911', deathdate: '1983' },
  { first_name: 'Arthur',  last_name: 'Miller',      birthdate: '1915', deathdate: '2005' },
]

authors.each do |attrs|
  Author.find_or_create_by!(last_name: attrs[:last_name], first_name: attrs[:first_name]) do |a|
    a.birthdate = attrs[:birthdate]
    a.deathdate = attrs[:deathdate]
  end
end

puts "Authors seeded: #{Author.count}"

# Only seed if no non-fake theaters exist
unless Theater.where(fake: false).exists?
  theater = Theater.create!(
    name: 'Shenandoah Valley Shakespeare',
    city: 'Harrisonburg',
    state: 'VA',
    mission_statement: 'Bringing Shakespeare to the Shenandoah Valley.',
    fake: false
  )

  # Make the seeded user a theater admin
  admin_specialization = Specialization.find_by(title: 'Theater Admin')
  first_user = User.first
  if admin_specialization && first_user
    Job.find_or_create_by!(
      theater_id: theater.id,
      user_id: first_user.id,
      specialization_id: admin_specialization.id
    )
  end

  puts "Theater seeded: #{theater.name}"
end

# Only seed if no canonical plays exist
unless Play.where(canonical: true).exists?
  shakespeare = Author.find_by(last_name: 'Shakespeare')
  chekhov = Author.find_by(last_name: 'Chekhov')

  # Hamlet
  hamlet = Play.create!(
    title: 'Hamlet',
    author: shakespeare,
    canonical: true,
    date: '1600',
    synopsis: 'Prince Hamlet seeks revenge against his uncle Claudius.'
  )

  Character.create!([
    { name: 'Hamlet', play: hamlet },
    { name: 'Ophelia', play: hamlet },
    { name: 'Claudius', play: hamlet },
    { name: 'Gertrude', play: hamlet },
    { name: 'Horatio', play: hamlet },
    { name: 'Polonius', play: hamlet },
  ])

  act1 = Act.create!(play: hamlet, number: 1)
  act2 = Act.create!(play: hamlet, number: 2)

  scene1_1 = Scene.create!(act: act1, number: 1)
  scene1_2 = Scene.create!(act: act1, number: 2)
  scene2_1 = Scene.create!(act: act2, number: 1)

  FrenchScene.create!(scene: scene1_1, number: 'a')
  FrenchScene.create!(scene: scene1_1, number: 'b')
  FrenchScene.create!(scene: scene1_2, number: 'a')
  FrenchScene.create!(scene: scene2_1, number: 'a')
  FrenchScene.create!(scene: scene2_1, number: 'b')

  puts "Seeded play: #{hamlet.title} with #{hamlet.acts.count} acts, #{hamlet.scenes.count} scenes, #{hamlet.french_scenes.count} french scenes"

  # The Cherry Orchard
  cherry_orchard = Play.create!(
    title: 'The Cherry Orchard',
    author: chekhov,
    canonical: true,
    date: '1904',
    synopsis: 'An aristocratic Russian family returns to their estate before it is auctioned.'
  )

  Character.create!([
    { name: 'Madame Ranevskaya', play: cherry_orchard },
    { name: 'Lopakhin', play: cherry_orchard },
    { name: 'Gayev', play: cherry_orchard },
    { name: 'Anya', play: cherry_orchard },
  ])

  act1_co = Act.create!(play: cherry_orchard, number: 1)
  act2_co = Act.create!(play: cherry_orchard, number: 2)

  scene1_co = Scene.create!(act: act1_co, number: 1)
  scene2_co = Scene.create!(act: act2_co, number: 1)

  FrenchScene.create!(scene: scene1_co, number: 'a')
  FrenchScene.create!(scene: scene1_co, number: 'b')
  FrenchScene.create!(scene: scene2_co, number: 'a')

  puts "Seeded play: #{cherry_orchard.title} with #{cherry_orchard.acts.count} acts, #{cherry_orchard.scenes.count} scenes, #{cherry_orchard.french_scenes.count} french scenes"

  puts "Total plays seeded: #{Play.where(canonical: true).count}"
end

# Add on_stages to Hamlet french scenes
hamlet = Play.find_by(title: 'Hamlet')
if hamlet && hamlet.french_scenes.any? && OnStage.where(french_scene: hamlet.french_scenes).none?
  hamlet_char = Character.find_by(name: 'Hamlet', play: hamlet)
  horatio = Character.find_by(name: 'Horatio', play: hamlet)
  claudius = Character.find_by(name: 'Claudius', play: hamlet)
  ophelia = Character.find_by(name: 'Ophelia', play: hamlet)

  fs1 = hamlet.french_scenes.first
  fs2 = hamlet.french_scenes.second

  if hamlet_char && horatio && fs1
    OnStage.find_or_create_by!(character: hamlet_char, french_scene: fs1) do |os|
      os.nonspeaking = false
    end
    OnStage.find_or_create_by!(character: horatio, french_scene: fs1) do |os|
      os.nonspeaking = false
    end
  end

  if hamlet_char && claudius && fs2
    OnStage.find_or_create_by!(character: hamlet_char, french_scene: fs2) do |os|
      os.nonspeaking = false
    end
    OnStage.find_or_create_by!(character: claudius, french_scene: fs2) do |os|
      os.nonspeaking = false
    end
    OnStage.find_or_create_by!(character: ophelia, french_scene: fs2) do |os|
      os.nonspeaking = true
    end
  end

  puts "OnStages seeded: #{OnStage.count}"
end

# Seed fake actors for doubling/casting planning
fake_actors = [
  { first_name: 'Fake', last_name: 'Actor 1', gender: 'cis female' },
  { first_name: 'Fake', last_name: 'Actor 2', gender: 'cis female' },
  { first_name: 'Fake', last_name: 'Actor 3', gender: 'cis male' },
  { first_name: 'Fake', last_name: 'Actor 4', gender: 'cis male' },
]

fake_actors.each do |attrs|
  User.find_or_create_by!(email: "#{attrs[:first_name].downcase}.#{attrs[:last_name].downcase.gsub(' ', '.')}@fake.example") do |u|
    u.first_name = attrs[:first_name]
    u.last_name  = attrs[:last_name]
    u.gender     = attrs[:gender]
    u.fake       = true
    u.provider   = 'fake'
    u.uid        = "fake-#{attrs[:last_name].downcase.gsub(' ', '-')}"
  end
end

puts "Fake actors seeded: #{User.where(fake: true).count}"

# Seed the primary dev user so they can log in via Google and manage productions
# (defined here so conflicts seed below can reference dev_user)
dev_user = User.find_or_create_by!(email: 'alisha.huber@gmail.com') do |u|
  u.first_name = 'Aili'
  u.last_name  = 'Huber'
  u.provider   = 'google_oauth2'
  u.uid        = 'alisha.huber@gmail.com'
end
dev_user.update!(role: 'superadmin') unless dev_user.superadmin?

# Seed a production if none exist
unless Production.exists?
  theater = Theater.find_by(fake: false)
  hamlet = Play.find_by(title: 'Hamlet', canonical: true)

  if theater && hamlet
    production = Production.create!(
      theater: theater,
      start_date: '2026-06-01',
      end_date: '2026-07-31',
    )
    # Assign play via PlayCopyWorker (mirrors real usage)
    PlayCopyWorker.perform_async(hamlet.id, production.id)
    puts "Production seeded: #{theater.name} – #{hamlet.title}"
  end
end

# Seed rehearsals for the Hamlet production
hamlet_production_for_rehearsals = Production.joins(:play).find_by(plays: { title: 'Hamlet' })
if hamlet_production_for_rehearsals && Rehearsal.where(production: hamlet_production_for_rehearsals).none?
  rehearsal_count = 0
  (0..13).each do |i|
    date = Date.today + i
    next if date.saturday? || date.sunday?
    Rehearsal.create!(
      production: hamlet_production_for_rehearsals,
      start_time: date.to_time + 19.hours,
      end_time:   date.to_time + 22.hours,
      title: "Rehearsal #{rehearsal_count + 1}",
    )
    rehearsal_count += 1
  end
  puts "Rehearsals seeded: #{rehearsal_count}"
end

# Give the dev user a Director job on the Hamlet production so they have admin access
theater = Theater.find_by(fake: false)
hamlet_production = Production.joins(:play).find_by(plays: { title: 'Hamlet' }, theater: theater)
director_specialization = Specialization.find_by(title: 'Director')

if hamlet_production && director_specialization && dev_user
  Job.find_or_create_by!(
    production_id: hamlet_production.id,
    theater_id:    theater.id,
    user_id:       dev_user.id,
    specialization_id: director_specialization.id
  )
  puts "Director job seeded for #{dev_user.email} on #{hamlet_production.play.title}"
end

# Seed conflicts for dev user
if dev_user && Conflict.where(user_id: dev_user.id).none?
  Conflict.create!(
    user: dev_user,
    start_time: Date.today + 3.days + 19.hours,
    end_time:   Date.today + 3.days + 21.hours,
    category:   'work'
  )

  ConflictPattern.create!(
    user:        dev_user,
    days_of_week: ['monday', 'wednesday'].to_json,
    start_time:  '09:00:00',
    end_time:    '17:00:00',
    start_date:  Date.today,
    end_date:    Date.today + 3.months,
    category:    'work'
  )

  puts "Conflicts seeded: #{Conflict.where(user_id: dev_user.id).count}"
  puts "Conflict patterns seeded: #{ConflictPattern.where(user_id: dev_user.id).count}"
end
