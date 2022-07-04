Rails.application.routes.draw do
  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'
  post 'auth/:provider/callback', to: 'sessions#create'

  get 'auth/failure', to: redirect('/')
  resources :sessions, only: %i(new create destroy)
  scope 'api' do
    resources :charges do
      collection do
        post :create_checkout_session
        post :update_payment_info
      end
    end
    resources :subscriptions do
      collection do
        get :get_subscriptions_for_user
        get :delete_subscription
        get :renew_subscription
      end
    end
    resources :users do
      member do
        get :create_customer
      end
      collection do
        get :fake
      end
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
        get :get_production_skeleton
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
      resources :jobs
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
      collection do
        get :play_titles
      end
      resources :words
      member do
        get :play_act_on_stages
        get :production_copy_complete
        get :play_french_scene_on_stages
        get :play_on_stages
        get :play_scene_on_stages
        get :play_script
        get :play_skeleton
        get :render_cut_part_script, format: 'docx'
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

          get :render_cut_script, format: 'docx'
          get :render_cuts_marked_part_script, format: 'docx'
        get :render_cuts_marked_script, format: 'docx'
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
