Rails.application.routes.draw do

  devise_for :users

  #
  # devise_for :users, :controllers => { :registrations => "registrations", :sessions => "sessions" }
  # devise_scope :user do get '/users/sign_out' => 'sessions#destroy' end
  # #devise_scope :user do match "/delete_users" => "registrations#delete_users", :as => 'delete_users' end
  # #match '/users/:id/edit' => 'admin_user_edit#edit', :as => :admin_user_edit
  # match '/users/update' => 'admin_user_edit#update', :as => :admin_user_update
  # match '/users/:id/list' => 'admin_user_edit#list', :as => :admin_user_list

  # admin_user_edit routes
  # match '/users/update' => 'admin_user_edit#update', :as => :admin_user_update
  # match '/users/:id/list' => 'admin_user_edit#list', :as => :admin_user_list

  get 'admin_user_edit/list'
  get 'admin_user_edit/delete_user'
  post 'admin_user_edit/update_user_roles'

  match 'services/render_props' => 'services#render_props', :as => :services_render_props, via: [:get]
  resources :services

  get 'prisme_job_queue/list'
  get 'prisme_job_queue/reload_job_queue_list'

  # get 'welcome/index'
  get 'welcome/tomcat_app_action' => 'welcome#tomcat_app_action'

  # NOTE: ensure that the first string passed is a unique string and will not match an action in the controller because
  # if Rails finds a match based on the name and based on the explicit mapping you use the action can get called TWICE!
  #
  # get '/toggle_admin' => 'welcome#toggle_admin' - THIS IS CALLED TWICE
  # match 'toggle-admin', to: 'welcome#toggle_admin', via: [:get]

  get 'app_deployer' => 'app_deployer#index'
  post 'app_deployer/deploy_app'

  get 'terminology_converter' => 'terminology_converter#index'
  get 'terminology_converter/load_build_data' => 'terminology_converter#ajax_load_build_data'
  get 'terminology_converter/check_polling' => 'terminology_converter#ajax_check_polling'
  get 'terminology_converter/term_source_change' => 'terminology_converter#ajax_term_source_change'
  post 'terminology_converter/request_build'

  root 'welcome#index'
  #root 'devise/sessions#new'

  # match 'logic_graph/chronology/:id' => 'logic_graph#chronology', :as => :logic_graph_chronology, via: [:get]

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
end
