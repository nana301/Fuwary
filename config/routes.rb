Rails.application.routes.draw do
  get "users/me", to: "users#show", as: :mypage
  devise_for :users

  root "home#index"

  # マイページ（ログインユーザー専用）
  resource :user, only: [:show]

  # health check / PWA
  get "up" => "rails/health#show", as: :rails_health_check
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
end
