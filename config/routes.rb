Rails.application.routes.draw do
  devise_for :users

  root to: 'articles#index'

  namespace :api, format: 'json' do
    namespace :v0 do
      resources :admin_cloudinary, only: %i[destroy]
    end
  end

  resources :articles do
    resources :images, only: %i[new create edit update destroy]
  end
end
