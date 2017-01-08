Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # enable this rule and copy public/maintenance.html to public/index.html
  # to turn on maintenance mode. this will override all of the other rules
  # and redirect all requests to a static text page.
  #match '*foo', :to => redirect('/maintenance.html')
  #root :to => redirect('/maintenance.html')
  
  get ":region/:realm/:name", :to => "characters#show", :as => :character, constraits: {region: /us|eu|kr|tw|cn|sea/i}
  get ":region/:realm/:name/refresh", :to => "characters#refresh", :as => :refresh_character, constraints: {region: /us|eu|kr|tw|cn|sea/i}
  get "error", :to => "application#error"
  get "missing", :to => "application#missing"
  get "persist", :to => "characters#persist"

  get "history/getsha", :to => "characters#getsha"
  get "history/getjson", :to => "characters#getjson"

  resources :characters do
    put 'refresh', :on => :member
    get 'refresh', :on => :member
  end
  resources :items do
    get 'rebuild', :on => :collection
  end

  get "items-:class", :to => "items#index", :class => /rogue/i
  root :to => "characters#new"
end
