Rails.application.routes.draw do
  class OnlyAjaxRequest
    def matches?(request)
      request.xhr?
    end
  end

  get 'roles/get_roles'
  get 'roles/get_ssoi_roles'
  get 'roles/get_roles_token', defaults: { format: 'text' }
  #ids like cshupp@gmail.com aren't valid in a URL :-(
  #match 'roles/get_roles/:id' => 'roles#get_roles', :as => :get_roles, via: [:get]


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

  get 'list_users' => 'admin_user_edit#list'
  get 'load_user_list' => 'admin_user_edit#ajax_load_user_list', :constraints => OnlyAjaxRequest.new
  post 'admin_user_edit/update_user_roles'
  match 'delete_user' => 'admin_user_edit#delete_user', as: 'delete_user', via: [:get]

  match 'services/render_props' => 'services#render_props', :as => :services_render_props, via: [:get]
  resources :services

  get 'terminology_source_packages' => 'terminology_source_packages#index'
  get 'terminology_source_packages/load_build_data' => 'terminology_source_packages#ajax_load_build_data'
  get 'terminology_source_packages/check_polling' => 'terminology_source_packages#ajax_check_polling'
  get 'terminology_source_packages/converter_change' => 'terminology_source_packages#ajax_converter_change'
  post 'terminology_source_packages' => 'terminology_source_packages#create'

  # DB BUILDER routes
  get 'terminology_db_builder' => 'terminology_db_builder#index'
  post 'terminology_db_builder/request_build'
  get 'terminology_db_builder/load_build_data' => 'terminology_db_builder#ajax_load_build_data'
  get 'terminology_db_builder/check_tag_conflict' => 'terminology_db_builder#ajax_check_tag_conflict'
  get 'terminology_db_builder/check_polling' => 'terminology_db_builder#ajax_check_polling'

  # welcome controller routes
  get 'welcome/tomcat_app_action' => 'welcome#tomcat_app_action'
  get 'welcome/reload_job_queue_list'
  get 'welcome/reload_deployments'

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
  get 'terminology_converter/ibdf_change' => 'terminology_converter#ajax_ibdf_change'
  get 'terminology_converter/converter_version_change' => 'terminology_converter#ajax_converter_version_change'
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
