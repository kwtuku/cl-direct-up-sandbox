Rails.application.routes.draw do
  devise_for :users

  root to: 'articles#index'

  resources :articles do
    resources :images, only: %i[new create edit update destroy]
  end
end
