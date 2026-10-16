Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  resources :screenings, only: :index

  namespace :mock_api do
    resources :screenings, only: :index
  end

  require "sidekiq/web"
  mount Sidekiq::Web => "/sidekiq"

  root "screenings#index"
end
