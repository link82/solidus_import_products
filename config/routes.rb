Spree::Core::Engine.routes.append do
  namespace :admin do
    resources :product_imports do
      put :presign_upload, on: :collection
    end
  end
end
