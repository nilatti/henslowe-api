require 'rails_helper'

describe BuildConflictsSchedule do
  before(:all) do
    @user = create(:user)
    @days_of_week = ['monday', 'wednesday', 'friday']
    @end_time = '16:30:00+5.00'
    @start_time = '14:30:00+5.00'
    @service = BuildConflictsSchedule.new(
      days_of_week: @days_of_week,
      end_time: @end_time,
      start_time: @start_time,
      user_id: @user.id
    )
  end
  it 'builds conflict days without specified start and end times' do
    days = @service.build_conflict_days(days_of_week: @days_of_week)
    expect(days.first.strftime("%a, %e %b %Y")).to eq(Date.today.strftime("%a, %e %b %Y"))
    expect(days.events.to_a.size).to be_within(3).of(156) #depends when in the week the test runs, exactly how many days we're hitting
  end
  it 'builds recurring conflicts' do
    conflicts_array = @service.build_conflicts(
      days_of_week: @days_of_week,
      end_time: @end_time,
      start_time: @start_time,
      user_id: @user.id
    )
    expect(conflicts_array.size).to be_within(3).of(156)
    expect(conflicts_array[0].start_time.strftime('%Y-%m-%d%l:%M:%S %z')).to eq(Date.today.strftime("%Y-%m-%d ") + '9:30:00 +0000')
    expect(conflicts_array[0].user_id).to eq(@user.id)
  end

  it 'builds and imports recurring conflicts' do
    @service.run(days_of_week: @days_of_week, end_time: @end_time, start_time: @start_time, user_id: @user.id)
    expect(Conflict.all.size).to be > 100
  end
end
