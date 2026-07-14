Rails.application.routes.draw do
  get '/up', to: proc { [200, {}, ['OK']] }
  post '/stripe/webhook', to: 'stripe_webhooks#create'

  require 'sidekiq/web'
  Sidekiq::Web.use(Rack::Auth::Basic) do |username, password|
    username == ENV.fetch('SIDEKIQ_USERNAME', '') &&
      ActiveSupport::SecurityUtils.secure_compare(password, ENV.fetch('SIDEKIQ_PASSWORD', ''))
  end
  mount Sidekiq::Web => '/sidekiq'

  # OmniAuth callback stays at /auth/:provider/callback but routes to namespaced controller
  get 'auth/:provider/callback', to: 'api/v1/sessions#create'
  get 'auth/failure', to: redirect('/')

  namespace :api do
    namespace :v1 do
      get 'open_auditions', to: 'open_auditions#index'
      get    'sessions/me',  to: 'sessions#me'
      delete 'sessions',     to: 'sessions#destroy'
      resources :charges do
        collection do
          post :create_checkout_session
          post :update_payment_info
        end
      end
      resources :subscriptions, only: [:index] do
        collection do
          get  :user_subscriptions
          post :cancel
          post :renew
        end
      end
      resources :users do
        member do
          post :create_customer
          put :build_conflict_schedule
          put :upload_headshot
          put :upload_resume
        end
        collection do
          get :fake
          post :generate_fake
        end
        resources :conflicts, shallow: true
        resources :conflict_patterns, shallow: true
      end
      resources :jobs
      resources :invitations, param: :token, only: [:index, :show, :destroy] do
        member do
          post :accept
          post :resend
        end
      end
      resources :specializations
      resources :phases
      resources :productions do
        resources :auditions, only: [:create]
        resources :jobs, shallow: true
        resources :invitations, only: [:create]
        resources :rehearsals, shallow: true
        resources :production_phases, shallow: true do
          collection do
            put :upsert
          end
        end
        member do
          put :build_rehearsal_schedule
          post :publish_rehearsal_calendar
          get :skeleton
          get :full
          get :user_conflicts
          get :space_conflicts
        end
        resources :stage_exits, shallow: true
        collection do
          get :production_names
        end
      end
      resources :theaters do
        resources :jobs
        resources :invitations, only: [:create]
        member do
          get :theater_skeleton
          post :create_seat_subscription_checkout_session
          patch :update_reserved_seats
        end
        collection do
          get :theater_names
        end
      end
      resources :spaces do
        resources :conflicts, shallow: true
        resources :conflict_patterns, shallow: true
        member do
          put :build_conflict_schedule
          get :rehearsals
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
        resources :acts, shallow: true do
          member do
            get :act_script
            get :render_cut_script, format: 'docx'
            get :render_cuts_marked_part_script, format: 'docx'
            get :render_cuts_marked_script, format: 'docx'
          end
          resources :scenes, shallow: true do
            member do
              get :scene_script
            end
            resources :french_scenes, shallow: true do
              member do
                get :french_scene_script
              end
              resources :lines, shallow: true
              resources :entrance_exits, shallow: true
              resources :on_stages, shallow: true
              resources :songs, shallow: true do
                member do
                  patch :move
                end
              end
              resources :rehearsals, shallow: true
            end
            resources :rehearsals, shallow: true
          end
          resources :rehearsals, shallow: true
        end
        resources :characters, shallow: true
        resources :character_groups, shallow: true
        resources :words, shallow: true
      end
      root to: "theaters#index"
      resources :labels
      resources :sound_cues
      resources :stage_directions
    end
  end
end
