Rails.application.routes.draw do
  # use_doorkeeper do
  #   skip_controllers :authorizations, :applications, :authorized_applications
  # end

  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'



  post 'auth/:provider/callback', to: 'sessions#create'

  get 'auth/failure', to: redirect('/')

  get 'signout', to: 'sessions#destroy', as: 'signout'
  resources :sessions, only: %i(new create destroy)
  scope 'api' do
  # devise_for :users,
  #            path: '',
  #            controllers: {
  #              omniauth_callbacks: 'users/omniauth_callbacks',
  #              sessions: 'sessions',
  #              registrations: 'registrations'
  #            }
  #  devise_scope :user do
  #    match '/users', to: 'registrations#create', via: :post
  #  end
    resources :users do
    # resources :users, only: [:create, :index, :show, :update, :destroy] do
      resources :conflicts
      resources :conflict_patterns
      member do
        put :build_conflict_schedule
      end
    end
    resources :jobs do
      collection do
        get :get_actors_for_production
        get :get_actors_and_auditioners_for_production
        get :get_actors_and_auditioners_for_theater
      end
    end
    resources :specializations
    resources :productions do
      resources :jobs
      resources :rehearsals
      member do
        put :build_rehearsal_schedule
        get :get_production_with_play_text
      end
      resources :stage_exits
      collection do
        get :production_names
        get :get_productions_for_theater
      end
    end
    resources :stage_exits

    resources :theaters do
      collection do
        get :theater_names
      end
    end
    resources :spaces do
      resources :conflicts
      resources :conflict_patterns
      member do
        put :build_conflict_schedule
      end
      collection do
        get :space_names
      end
    end
    resources :authors do
      collection do
        get :author_names
      end
      resources :plays
    end
    resources :plays do
      resources :words
      collection do
        get :play_titles
      end
      member do
        get :play_act_on_stages
        get :production_copy_complete
        get :play_french_scene_on_stages
        get :play_on_stages
        get :play_scene_on_stages
        get :play_script
        get :play_skeleton
      end

      resources :acts do
        resources :scenes
        resources :rehearsals
      end
      resources :characters
      resources :character_groups
    end
    root to: "theaters#index"
    resources :acts do
      member do
        get :act_script
      end
      resources :scenes
      resources :rehearsals
    end
    resources :characters
    resources :character_groups
    resources :scenes do
      member do
        get :scene_script
      end
      resources :rehearsals
      resources :french_scenes
    end
    resources :french_scenes do
      resources :rehearsals
      resources :lines
      member do
        get :french_scene_script
      end
      resources :entrance_exits
      resources :on_stages
    end
    resources :conflicts
    resources :conflict_patterns
    resources :entrance_exits
    resources :jobs
    resources :labels
    resources :lines
    resources :on_stages
    resources :rehearsals
    resources :sound_cues
    resources :stage_directions
  end
end
