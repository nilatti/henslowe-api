require 'rails_helper'

describe CopyPlayForProduction do
  before(:all) do
    @production = create(:production)
    @original_play = create(:play, :with_full_structure, canonical: true) #this play has three acts. each act has 3 scenes. each scene has 3 french scenes.
    first_act = @original_play.acts.first
    @first_scene = first_act.scenes.first
    character1 = create(:character, play: @original_play)
    character2 = create(:character, play: @original_play)
    create(:specialization, title: "Actor")
    create(:on_stage, french_scene: @first_scene.french_scenes.first, character: character1)
    create(:on_stage, french_scene: @first_scene.french_scenes.first, character: character2)
    @copier = CopyPlayForProduction.new(play_id: @original_play.id, production_id: @production.id)
    @copier.run
    @copy_of_play = @copier.new_play
  end

  it 'copies the play attributes' do
    expect(@copy_of_play.title).to eq(@original_play.title)
    expect(@copy_of_play.author).to eq(@original_play.author)
    expect(@copy_of_play.genre).to eq(@original_play.genre)
    expect(@copy_of_play.canonical).to be(false)
  end

  it 'copies the play acts' do
    expect(@copy_of_play.acts.size).to eq(@original_play.acts.size)
    expect(@copy_of_play.acts.first.number).to eq(@original_play.acts.first.number)
    expect(@copy_of_play.acts.first.play.id).to be(@copy_of_play.id)
  end

  it 'copies the play scenes' do
    new_act = @copy_of_play.acts.first
    old_act = @original_play.acts.first
    expect(new_act.scenes.first.number).to eq(old_act.scenes.first.number)
    expect(@copy_of_play.scenes.size).to eq(@original_play.scenes.size)
    expect(new_act.scenes.first.act.id).not_to be(old_act.id)
  end

  it 'copies the play french scenes' do
    new_scene = @copy_of_play.scenes.first
    old_scene = @original_play.scenes.first
    expect(new_scene.french_scenes.first.number).to eq(old_scene.french_scenes.first.number)
    expect(new_scene.french_scenes[0].scene_id).to eq(new_scene.french_scenes[1].scene_id)
    expect(@copy_of_play.french_scenes.size).to eq(@original_play.french_scenes.size)
    expect(new_scene.french_scenes.first.scene.id).not_to be(old_scene.id)
  end

  it 'copies the on_stages' do
    new_french_scene = @copy_of_play.acts.first.scenes.first.french_scenes.first
    old_french_scene = @first_scene.french_scenes.first
    expect(new_french_scene.on_stages.size).to eq(old_french_scene.on_stages.size)
    expect(new_french_scene.on_stages.first.french_scene.id).not_to be(old_french_scene.id)
    expect(new_french_scene.on_stages.first.character_id).not_to be(old_french_scene.on_stages.first.character_id)
    expect(new_french_scene.on_stages.first.character.name).to eq(old_french_scene.on_stages.first.character.name)
  end

  it 'creates castings for production' do
    expect(@production.jobs.size).to eq(5)
    expect(@production.jobs[0].specialization.title).to eq('Actor')
    expect(@production.jobs[0].character.name).not_to be('')
  end
end
