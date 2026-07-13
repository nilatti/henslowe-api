class PublishRehearsalCalendarWorker
  include Sidekiq::Worker

  def perform(production_id)
    PublishRehearsalCalendar.new(Production.find(production_id)).run
  end
end
