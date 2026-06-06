class ProductionDestroyWorker
  include Sidekiq::Worker

  def perform(production_id)
    production = Production.find_by(id: production_id)
    production&.destroy
  end
end
