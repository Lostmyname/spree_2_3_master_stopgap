Spree::Core::Engine.routes.draw do

  namespace :admin do
    resources :orders do
      member do
        get :state_changes
      end
    end
  end

end
