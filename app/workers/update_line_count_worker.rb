class UpdateLineCountWorker
  include SuckerPunch::Job

  def perform(line_id)
    puts ('perform called')
    CountLines.new(line_id: line_id).run
  end
end
