Rails.application.routes.draw do
  apipie
  class OnlyAjaxRequest
    def matches?(request)
      request.xhr?
    end
  end
  match '/vuid/request' => 'vuid#rest_request_vuid', :as => :rest_request_vuid, via: [:get,:put,:post]
  match '/vuid/view' => 'vuid#rest_fetch_vuids', :as => :rest_fetch_vuids, via: [:get,:put,:post]
  get 'vuid_requests' => 'vuid#index'
  get 'vuid_poll' => 'vuid#ajax_vuid_polling', :constraints => OnlyAjaxRequest.new
  post 'request_vuid' => 'vuid#request_vuid'

  get 'hl7_messaging/checksum', as: 'checksum'
  get 'hl7_messaging/discovery', as: 'discovery'
  get 'hl7_messaging/discovery_csv', as: 'discovery_csv'
  get 'hl7_messaging/retrieve_sites'
  get 'hl7_messaging/checksum_request_poll', as: 'checksum_request_poll'
  get 'hl7_messaging/discovery_request_poll', as: 'discovery_request_poll'
  get 'hl7_messaging/isaac_hl7', as: 'isaac_hl7'
  post 'hl7_messaging/hl7_messaging_results_table', as: 'hl7_messaging_results_table'

  #resources :log_events
  match 'log_event' => 'log_events#log_event', :as => :log_event, via: [:get, :put, :post]
  post 'log_events/acknowledge_log_event', as: :acknowledge_log_event, :constraints => OnlyAjaxRequest.new

  # javascript timer checking user session timeout
  get 'welcome/session_timeout', as: :session_timeout
  get 'welcome/renew_session', as: :renew_session, :constraints => OnlyAjaxRequest.new
  get 'welcome/rename_war', as: :rename_war, :constraints => OnlyAjaxRequest.new
  get 'welcome/check_isaac_dependency', as: :check_isaac_dependency

  get 'utilities/warmup'
  get 'utilities/time_stats'
  get 'utilities/browser_tz_offset'
  get 'utilities/seed_services'
  get 'utilities/prisme_config'
  get 'utilities/log_level'
  get 'utilities/git_not_available', as: :git_not_available
  get 'utilities/nexus_not_available', as: :nexus_not_available
  get 'utilities/not_configured', as: :not_configured
  get 'utilities/terminology_config_error', as: :terminology_config_error


  get 'roles/get_all_roles'#isaac rest is dependent on this route
  get 'roles/get_user_roles'# # Komet is dependent on this route
  get 'roles/get_ssoi_roles' #mod_perl (apache extensions), komet are dependent on this route
  get 'roles/get_roles_by_token' #isaac rest is dependent on this route

  # get 'roles/get_roles_token', defaults: { format: 'text' } used for a demo
  #ids like cshupp@gmail.com aren't valid in a URL :-(
  #match 'roles/get_user_roles/:id' => 'roles#get_user_roles', :as => :get_user_roles, via: [:get]

  get 'roles/sso_logout'

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
  match 'services/all_services_as_json' => 'services#all_services_as_json', :as => :all_services_as_json, via: [:get]
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
  get 'terminology_db_builder/check_cradle_conflict' => 'terminology_db_builder#ajax_check_cradle_conflict', :constraints => OnlyAjaxRequest.new
  get 'terminology_db_builder/check_polling' => 'terminology_db_builder#ajax_check_polling'

  # welcome controller routes
  get 'welcome/tomcat_app_action' => 'welcome#tomcat_app_action'
  get 'welcome/reload_job_queue_list'
  get 'welcome/reload_deployments'
  get 'welcome/reload_log_events', :constraints => OnlyAjaxRequest.new

  # NOTE: ensure that the first string passed is a unique string and will not match an action in the controller because
  # if Rails finds a match based on the name and based on the explicit mapping you use the action can get called TWICE!
  #
  # get '/toggle_admin' => 'welcome#toggle_admin' - THIS IS CALLED TWICE
  # match 'toggle-admin', to: 'welcome#toggle_admin', via: [:get]

  get 'app_deployer' => 'app_deployer#index'
  get 'app_deployer/reload_deployments', :constraints => OnlyAjaxRequest.new
  get 'app_deployer/check_polling' => 'app_deployer#ajax_check_polling', :constraints => OnlyAjaxRequest.new
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
