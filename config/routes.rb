Rails.application.routes.draw do
  root to: 'home#index'
  match '/search', to: 'home#search', via: [:post]
  get 'topics', controller: 'home'

  get '/healthcheck', to: 'healthcheck#check'

  resources :shows, only: [:index, :show]
end
