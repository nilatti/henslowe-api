require 'rails_helper'

describe BuildConflictsSchedule do
  context 'builds conficts for users' do
    before(:each) do
      @user = create(:user)
      @category = "work"
      @days_of_week = ['monday', 'tuesday', 'friday']
      @end_date = '2020-06-23'
      @end_time = '16:30:00+5.00'
      @start_date = '2020-04-24'
      @start_time = '14:30:00+5.00'
      @service_without_dates = BuildConflictsSchedule.new(
        category: @category,
        days_of_week: @days_of_week,
        end_time: @end_time,
        space_id: nil,
        start_time: @start_time,
        user_id: @user.id
      )
      @service_with_dates = BuildConflictsSchedule.new(
        category: @category,
        days_of_week: @days_of_week,
        end_date: @end_date,
        end_time: @end_time,
        space_id: nil,
        start_date: @start_date,
        start_time: @start_time,
        user_id: @user.id
      )
    end
    it 'builds conflict days with specified start and end times' do
      days = @service_with_dates.build_conflict_days
      expect(days.first.strftime("%a, %e %b %Y")).to eq(Date.parse(@start_date).strftime("%a, %e %b %Y"))
      expect(days.events.to_a.size).to eq(27)
    end
    it 'builds recurring conflicts' do
      conflicts_array = @service_with_dates.build_conflicts
      expect(conflicts_array.size).to eq(27)
      expect(conflicts_array[0].start_time.strftime('%Y-%m-%d%l:%M:%S %z')).to eq(Date.parse(@start_date).strftime("%Y-%m-%d ") + '9:30:00 +0000')
      expect(conflicts_array[0].user_id).to eq(@user.id)
      expect(conflicts_array[0].category).to eq(@category)
      expect(conflicts_array[0].regular).to be true
    end

    it 'builds and imports recurring conflicts without specific dates' do
      @service_without_dates.run
      expect(Conflict.all.size).to be > 100
    end

    it 'builds and imports recurring conflicts with specific dates' do
      @service_with_dates.run
      expect(Conflict.all.size).to eq(27)
    end
  end

  context 'builds conficts for spaces' do
    before(:each) do
      @space = create(:space)
      @category = "work"
      @days_of_week = ['monday', 'tuesday', 'friday']
      @end_date = '2020-06-23'
      @end_time = '16:30:00+5.00'
      @start_date = '2020-04-24'
      @start_time = '14:30:00+5.00'
      @service_without_dates = BuildConflictsSchedule.new(
        category: @category,
        days_of_week: @days_of_week,
        end_time: @end_time,
        space_id: @space.id,
        start_time: @start_time,
        user_id: nil
      )
      @service_with_dates = BuildConflictsSchedule.new(
        category: @category,
        days_of_week: @days_of_week,
        end_date: @end_date,
        end_time: @end_time,
        space_id: @space.id,
        start_date: @start_date,
        start_time: @start_time,
        user_id: nil
      )
    end
    it 'builds conflict days with specified start and end times' do
      days = @service_with_dates.build_conflict_days
      expect(days.first.strftime("%a, %e %b %Y")).to eq(Date.parse(@start_date).strftime("%a, %e %b %Y"))
      expect(days.events.to_a.size).to eq(27)
    end
    it 'builds recurring conflicts' do
      conflicts_array = @service_with_dates.build_conflicts
      expect(conflicts_array.size).to eq(27)
      expect(conflicts_array[0].start_time.strftime('%Y-%m-%d%l:%M:%S %z')).to eq(Date.parse(@start_date).strftime("%Y-%m-%d ") + '9:30:00 +0000')
      expect(conflicts_array[0].space_id).to eq(@space.id)
      expect(conflicts_array[0].category).to eq(@category)
      expect(conflicts_array[0].regular).to be true
    end

    it 'builds and imports recurring conflicts without specific dates' do
      @service_without_dates.run
      expect(Conflict.all.size).to be > 100
    end

    it 'builds and imports recurring conflicts with specific dates' do
      @service_with_dates.run
      expect(Conflict.all.size).to eq(27)
    end
  end
end
