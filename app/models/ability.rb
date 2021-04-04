# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)

    user ||= User.new
    if user.superadmin?
      can :manage, :all

    elsif user.regular?
      can :manage, Theater do |theater|
        user.theater_admin?(theater)
      end

      can :manage, Production do |production|
        user.production_admin?(production) || user.theater_admin?(production.theater)
      end

      can :manage, Play do |play|
        if play.canonical?
          false
        else
          user.production_admin_for_play?(play) || user.theater_admin_for_play?(play)
        end
      end
      
      can :manage, Job do |job|
        user.theater_admin?(job.theater) || user.production_admin?(job.production)
      end

      can :read, Theater, jobs: { :user_id => user.id }
      can :read, Production, jobs: { :user_id => user.id }
      can :read, [Act, Scene, FrenchScene, Character]
      can :read, Author
      can :read, Play
      can [:show], User
      cannot :index, User
      can :manage, User, :id => user.id
      cannot :read, Job
      can :read, Job, :user_id => user.id

    elsif user.first_name == nil
      cannot :read, :all
      can :read, Welcome
      #generic welcome page is all they can see
    end
   end
end
