# Shared by the drag-to-reorder endpoints for acts, scenes, French scenes and
# script items. Only a production's copy of a play can be reordered; canonical
# plays keep their original order.
module PlayReordering
  extend ActiveSupport::Concern

  class InvalidOrder < StandardError; end

  included do
    rescue_from PlayReordering::InvalidOrder do |e|
      render json: { message: e.message }, status: :unprocessable_entity
    end
  end

  private

  def authorize_reorder!(play)
    authorize! :update, play
    raise InvalidOrder, 'Only production copies of a play can be reordered' if play.canonical?
  end

  # ids is the complete new order of `scope`'s records. Writes position 1..n.
  def apply_order!(scope, ids)
    ids = Array(ids).map(&:to_i)
    unless ids.uniq.size == ids.size && ids.sort == scope.pluck(:id).sort
      raise InvalidOrder, 'The new order must list every item exactly once'
    end

    scope.klass.transaction do
      scope.klass.unscoped.where(id: ids).update_all(position_case_sql(ids))
    end
  end

  # "position = CASE id WHEN 7 THEN 1 WHEN 3 THEN 2 ... END". ids are integers,
  # so interpolating them is safe.
  def position_case_sql(ids)
    whens = ids.each_with_index.map { |id, i| "WHEN #{id.to_i} THEN #{i + 1}" }.join(' ')
    "position = CASE id #{whens} END"
  end
end
