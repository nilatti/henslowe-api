# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new
    return unless user.present?

    cannot :index, User
    can :read, User
    can :manage, User, { id: user.id }
    can :show, User do |target_user|
      user.jobs_overlap(target_user) == "theater admin"
    end

    if user.superadmin?
      can :index, User
      can :manage, :all

    elsif user.regular?
      can :manage, Conflict, user_id: user.id
      can :manage, ConflictPattern, user_id: user.id

      can :manage, Theater do |theater|
        user.theater_admin?(theater)
      end

      can :manage, Production do |production|
        user.production_admin?(production) || user.theater_admin?(production.theater)
      end

      can :manage, ProductionPhase do |pp|
        user.production_admin?(pp.production) || user.theater_admin?(pp.production.theater)
      end

      can :read, Phase

      can :manage, Play do |play|
        if play.canonical?
          false
        else
          user.production_admin_for_play?(play) || user.theater_admin_for_play?(play)
        end
      end

      can :create, Job do |job|
        job.user_id == user.id && Specialization.auditioner.include?(job.specialization)
      end
      can :update, Job, user_id: user.id
      can :manage, Job do |job|
        user.theater_admin?(job.theater) || user.production_admin?(job.production)
      end

      can :manage, Invitation do |invitation|
        user.theater_admin?(invitation.theater) || user.production_admin?(invitation.production)
      end
      can :accept, Invitation do |invitation|
        invitation.email == user.email.to_s.strip.downcase
      end

      can :read, Theater, jobs: { :user_id => user.id }
      can :read, Production, jobs: { :user_id => user.id }
      can :read, [Act, Scene, FrenchScene, Character]
      can :read, Author
      can :read, Play
      # can [:show], User
      # cannot :index, User
      can :manage, User, :id => user.id
      cannot :read, Job
      can :read, Job, :user_id => user.id
      can :read, Job do |job|
        user.theater_admin?(job.theater) || user.production_admin?(job.production)
      end

    elsif user.first_name == nil
      cannot :read, :all
      can :read, Welcome
      #generic welcome page is all they can see
    end
   end
end
