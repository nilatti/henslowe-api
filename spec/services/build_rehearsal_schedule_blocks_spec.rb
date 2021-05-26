require 'rails_helper'

describe BuildRehearsalScheduleBlocks do
  before(:all) do
    @production = create(:production)
    @users = create_list(:user, 3)
    @break_length = 5
    @days_of_week = ['monday', 'wednesday', 'friday']
    @default_user_ids = @users.each {|u| u.id}
    @end_date = '2020-04-23'
    @end_time = '16:30:00+5.00'
    @start_date = '2020-04-14'
    @start_time = '14:30:00+5.00'
    @time_between_breaks = 55

    @service = BuildRehearsalScheduleBlocks.new(break_length: @break_length, days_of_week: @days_of_week, default_user_ids: @default_user_ids, end_date: @end_date, end_time: @end_time, production_id: @production.id, time_between_breaks: @time_between_breaks, start_date: @start_date, start_time: @start_time)
  end
  it 'builds rehearsal blocks' do
    blocks = @service.build_rehearsal_blocks(break_length: @break_length, end_time: @end_time, start_time: @start_time, time_between_breaks: @time_between_breaks)
    expect(blocks.size).to eq(4)
    expect((blocks.first[:start_time]).hour).to be(9) #saves in UTC
    expect((blocks.first[:start_time]).min).to be(30)
    expect((blocks.first[:end_time]).hour).to be(10)
    expect((blocks.first[:end_time]).min).to be(00)
    expect((blocks[1][:start_time]).hour).to be(10)
    expect((blocks[1][:start_time]).min).to be(00)
    expect((blocks[1][:end_time]).hour).to be(10)
    expect((blocks[1][:end_time]).min).to be(25)
    expect((blocks[2][:start_time]).hour).to be(10)
    expect((blocks[2][:start_time]).min).to be(30)
  end
  it 'builds rehearsal days' do
    days = @service.build_rehearsal_days(days_of_week: @days_of_week, end_date: @end_date, start_date: @start_date)
    expect(days.first.strftime('%F')).to eq('2020-04-15')
  end
  it 'builds recurring rehearsals' do
    rehearsal_blocks_array = @service.build_recurring_rehearsals(
      break_length: @break_length,
      days_of_week: @days_of_week,
      default_users: @users,
      end_date: @end_date,
      end_time: @end_time,
      start_date: @start_date,
      start_time: @start_time,
      time_between_breaks: @time_between_breaks
    )
    expect(rehearsal_blocks_array.size).to eq(16)
    expect(rehearsal_blocks_array[0].start_time).to eq('2020-04-15 09:30:00.000000000 +0000')
    expect(rehearsal_blocks_array[4].start_time).to eq('2020-04-17 09:30:00.000000000 +0000')
    expect(rehearsal_blocks_array[0].user_ids).to include(@users[0].id)
  end
end
