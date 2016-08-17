# coding: utf-8
Roguesim::Application.routes.draw do

  # enable this rule and copy public/maintenance.html to public/index.html
  # to turn on maintenance mode. this will override all of the other rules
  # and redirect all requests to a static text page.
  #match '*foo', :to => redirect('/maintenance.html')
  #root :to => redirect('/maintenance.html')
  
  match "/:region/:realm/:name", :to => "characters#show", :as => :character, :region => /us|eu|kr|tw|cn|sea/i
  match "/:region/:realm/:name/refresh", :to => "characters#refresh", :as => :refresh_character, :region => /us|eu|kr|tw|cn|sea/i
  match "/error", :to => "application#error"
  match "/missing", :to => "application#missing"
  match "/persist", :to => "characters#persist"

  match "/history/getsha", :to => "characters#getsha"
  match "/history/getjson", :to => "characters#getjson"

  resources :characters do
    put 'refresh', :on => :member
    get 'refresh', :on => :member
  end
  resources :items do
    get 'rebuild', :on => :collection
  end

  match "/items-:class", :to => "items#index", :class => /rogue/i
  root :to => "characters#new"
end
