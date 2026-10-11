require 'rails_helper'

RSpec.describe 'Play reordering API' do
  let!(:theater) { create(:theater) }
  let!(:production) { create(:production, theater: theater) }
  let!(:play) { create(:play, :with_full_structure, canonical: false, production: production) }
  let!(:superadmin) { create(:user, :superadmin) }
  let!(:production_admin) { create(:user, :paid) }
  let!(:outsider) { create(:user) }
  let(:acts) { play.reload.acts.to_a }

  before do
    create(:job, user: production_admin, theater: theater, production: production,
                 specialization: create(:specialization, :director), start_date: 1.year.ago, end_date: 1.year.from_now)
  end

  describe 'PUT /api/v1/plays/:id/reorder_acts' do
    let(:new_order) { [acts[2].id, acts[0].id, acts[1].id] }

    it 'reorders the acts without changing their numbers' do
      numbers = acts.map { |a| [a.id, a.number] }.to_h
      put "/api/v1/plays/#{play.id}/reorder_acts", params: { ids: new_order }, as: :json, headers: authenticated_header(superadmin)

      expect(response).to have_http_status(204)
      expect(play.reload.acts.map(&:id)).to eq(new_order)
      expect(play.acts.map { |a| [a.id, a.number] }.to_h).to eq(numbers)
    end

    it "lets the production's admin reorder" do
      put "/api/v1/plays/#{play.id}/reorder_acts", params: { ids: new_order }, as: :json, headers: authenticated_header(production_admin)
      expect(response).to have_http_status(204)
    end

    it 'forbids users who cannot manage the production' do
      put "/api/v1/plays/#{play.id}/reorder_acts", params: { ids: new_order }, as: :json, headers: authenticated_header(outsider)
      expect(response).to have_http_status(403)
    end

    it 'refuses canonical plays' do
      play.update!(canonical: true)
      put "/api/v1/plays/#{play.id}/reorder_acts", params: { ids: new_order }, as: :json, headers: authenticated_header(superadmin)
      expect(response).to have_http_status(422)
    end

    it 'refuses an order that leaves an act out' do
      put "/api/v1/plays/#{play.id}/reorder_acts", params: { ids: new_order.first(2) }, as: :json, headers: authenticated_header(superadmin)
      expect(response).to have_http_status(422)
      expect(play.reload.acts.map(&:id)).to eq(acts.map(&:id))
    end

    it 'puts the reordered acts in play order everywhere acts are listed' do
      put "/api/v1/plays/#{play.id}/reorder_acts", params: { ids: new_order }, as: :json, headers: authenticated_header(superadmin)
      get "/api/v1/plays/#{play.id}/play_skeleton", headers: authenticated_header(superadmin)
      expect(json['acts'].map { |a| a['id'] }).to eq(new_order)
      get "/api/v1/plays/#{play.id}/play_scene_on_stages", headers: authenticated_header(superadmin)
      expect(json.map { |s| s['act_id'] }.uniq).to eq(new_order)
    end
  end

  describe 'PUT /api/v1/acts/:id/reorder_scenes' do
    let(:act) { acts.first }
    let(:scenes) { act.scenes.to_a }
    let(:new_order) { [scenes[1].id, scenes[2].id, scenes[0].id] }

    it 'reorders the scenes within the act' do
      put "/api/v1/acts/#{act.id}/reorder_scenes", params: { ids: new_order }, as: :json, headers: authenticated_header(superadmin)
      expect(response).to have_http_status(204)
      expect(act.reload.scenes.map(&:id)).to eq(new_order)
    end

    it "refuses a scene from another act" do
      foreign = acts.last.scenes.first.id
      put "/api/v1/acts/#{act.id}/reorder_scenes", params: { ids: new_order.first(2) + [foreign] }, as: :json, headers: authenticated_header(superadmin)
      expect(response).to have_http_status(422)
    end
  end

  describe 'PUT /api/v1/scenes/:id/reorder_french_scenes' do
    let(:scene) { acts.first.scenes.first }
    let(:french_scenes) { scene.french_scenes.to_a }
    let(:new_order) { french_scenes.map(&:id).reverse }

    it 'reorders the French scenes within the scene, keeping their labels' do
      labels = french_scenes.map(&:pretty_name)
      put "/api/v1/scenes/#{scene.id}/reorder_french_scenes", params: { ids: new_order }, as: :json, headers: authenticated_header(superadmin)
      expect(response).to have_http_status(204)
      expect(scene.reload.french_scenes.map(&:id)).to eq(new_order)
      expect(scene.french_scenes.map(&:pretty_name)).to eq(labels.reverse)
    end
  end

  describe 'PUT /api/v1/plays/:id/reorder_script_items' do
    let(:fs_a) { acts.first.scenes.first.french_scenes.first }
    let(:fs_b) { acts.first.scenes.first.french_scenes.second }
    let(:hamlet) { play.characters.first }
    let!(:line1) { create(:line, french_scene: fs_a, number: '1.1.1', character: hamlet) }
    let!(:line2) { create(:line, french_scene: fs_a, number: '1.1.2', character: hamlet) }
    let!(:direction) { create(:stage_direction, french_scene: fs_a, number: 'SD 1.1.2.1') }
    let!(:line3) { create(:line, french_scene: fs_b, number: '1.1.3', character: play.characters.second) }
    let!(:cue) { create(:sound_cue, french_scene: fs_b, line_number: '1.1.3') }

    def reorder(french_scenes, user = superadmin)
      put "/api/v1/plays/#{play.id}/reorder_script_items", params: { french_scenes: french_scenes }, as: :json, headers: authenticated_header(user)
    end

    it 'reorders items within a French scene' do
      reorder([{ id: fs_a.id, items: [{ type: 'stage_direction', id: direction.id }, { type: 'line', id: line2.id }, { type: 'line', id: line1.id }] }])

      expect(response).to have_http_status(204)
      expect(direction.reload.position).to eq(1)
      expect(line2.reload.position).to eq(2)
      expect(line1.reload.position).to eq(3)
      expect(line1.number).to eq('1.1.1')
    end

    it "moves a line into another French scene and adds its speaker there" do
      expect(fs_b.on_stages.where(character: hamlet)).to be_empty

      reorder([
        { id: fs_a.id, items: [{ type: 'line', id: line1.id }, { type: 'stage_direction', id: direction.id }] },
        { id: fs_b.id, items: [{ type: 'line', id: line3.id }, { type: 'line', id: line2.id }, { type: 'sound_cue', id: cue.id }] },
      ])

      expect(response).to have_http_status(204)
      expect(line2.reload.french_scene_id).to eq(fs_b.id)
      expect(line2.position).to eq(2)
      expect(cue.reload.position).to eq(3)
      expect(fs_b.on_stages.where(character: hamlet).count).to eq(1)
    end

    it 'accepts a French scene emptied by the move' do
      reorder([
        { id: fs_b.id, items: [] },
        { id: fs_a.id, items: [{ type: 'line', id: line1.id }, { type: 'line', id: line2.id }, { type: 'stage_direction', id: direction.id },
                               { type: 'line', id: line3.id }, { type: 'sound_cue', id: cue.id }] },
      ])
      expect(response).to have_http_status(204)
      expect(fs_b.reload.lines).to be_empty
    end

    it 'refuses an order that leaves out an item of a listed French scene' do
      reorder([{ id: fs_a.id, items: [{ type: 'line', id: line2.id }, { type: 'line', id: line1.id }] }])
      expect(response).to have_http_status(422)
      expect(line1.reload.position).to be_nil
    end

    it 'refuses items from another play' do
      other = create(:line)
      reorder([{ id: fs_a.id, items: [{ type: 'line', id: line1.id }, { type: 'line', id: line2.id }, { type: 'stage_direction', id: direction.id }, { type: 'line', id: other.id }] }])
      expect(response).to have_http_status(422)
    end

    it 'forbids users who cannot manage the production' do
      reorder([{ id: fs_a.id, items: [{ type: 'line', id: line1.id }, { type: 'line', id: line2.id }, { type: 'stage_direction', id: direction.id }] }], outsider)
      expect(response).to have_http_status(403)
    end

    it 'returns positions in the play script' do
      reorder([{ id: fs_a.id, items: [{ type: 'line', id: line2.id }, { type: 'line', id: line1.id }, { type: 'stage_direction', id: direction.id }] }])
      get "/api/v1/plays/#{play.id}/play_script", headers: authenticated_header(superadmin)
      fs = json['acts'][0]['scenes'][0]['french_scenes'][0]
      expect(fs['lines'].map { |l| [l['id'], l['position']] }).to contain_exactly([line1.id, 2], [line2.id, 1])
    end
  end

  describe 'new structure' do
    it 'adds a new act at the end of the play order' do
      act = create(:act, play: play, number: 0)
      expect(play.reload.acts.last).to eq(act)
    end
  end
end
