Rails.application.routes.draw do
  devise_for :users

  root "home#index"

  resource :user, only: [:show]
  get "users/me", to: "users#show", as: :mypage

  resources :tarot_results, only: %i[create show] do
    collection do
      get :new_genre
      get :new_emotion
    end

    member do
      post :draw
    end
  end

  get "guest_tarot_result", to: "tarot_results#guest", as: :guest_tarot_result

  get "up" => "rails/health#show", as: :rails_health_check
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
end

