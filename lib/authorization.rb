module Authorization
  THEATER_ADMIN_TITLES = [
    'Executive Director',
    'Artistic Director',
    'Technical Director',
    'Theater Admin'
  ].freeze

  PRODUCTION_ADMIN_TITLES = [
    'Producer',
    'Director',
    'Stage Manager',
    'Production Admin'
  ].freeze

  def superadmin?(user)
    user.role == 'superadmin' ||
      (Rails.application.credentials.superusers || []).include?(user.email)
  end

  def theater_admin?(user, theater_id)
    return true if superadmin?(user)
    user.jobs
        .where(theater_id: theater_id, production_id: nil)
        .joins(:specialization)
        .where(specializations: { title: THEATER_ADMIN_TITLES })
        .exists?
  end

  def theater_member?(user, theater_id)
    return true if theater_admin?(user, theater_id)
    user.jobs.where(theater_id: theater_id).exists?
  end

  def production_admin?(user, production_id)
    return true if superadmin?(user)
    production = Production.find(production_id)
    return true if theater_admin?(user, production.theater_id)
    user.jobs
        .where(production_id: production_id)
        .joins(:specialization)
        .where(specializations: { title: THEATER_ADMIN_TITLES + PRODUCTION_ADMIN_TITLES })
        .exists?
  end

  def production_member?(user, production_id)
    return true if production_admin?(user, production_id)
    production = Production.find(production_id)
    return true if theater_member?(user, production.theater_id)
    user.jobs.where(production_id: production_id).exists?
  end

  def authorize_superadmin!
    render json: { error: 'Forbidden' }, status: :forbidden unless superadmin?(current_user)
  end

  def authorize_theater_admin!(theater_id)
    render json: { error: 'Forbidden' }, status: :forbidden unless theater_admin?(current_user, theater_id)
  end

  def authorize_production_admin!(production_id)
    render json: { error: 'Forbidden' }, status: :forbidden unless production_admin?(current_user, production_id)
  end

  def authorize_production_member!(production_id)
    render json: { error: 'Forbidden' }, status: :forbidden unless production_member?(current_user, production_id)
  end
end
