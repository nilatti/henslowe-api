Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  scope 'api' do
    resources :theaters do
      collection do
        get :theater_names
      end
    end
    resources :authors do
      collection do
        get :author_names
      end
      resources :plays
    end
    resources :plays do
      resources :acts
      resources :characters
    end
    resources :acts
    resources :characters
  end
end
