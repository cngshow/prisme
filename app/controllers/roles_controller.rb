require 'uri'
require 'cgi'
class RolesController < ApplicationController

  USER_PREAMBLE = :user_

  resource_description do
    short 'Role APIs'
    formats ['json', 'html']
  end

  skip_after_action :verify_authorized
  skip_before_action :verify_authenticity_token
  skip_after_action :log_user_activity #urls with tokens are too long to record in oracle
  force_ssl if: :ssl_configured_delegator? # port: 8443

  def sso_logout
    # remove the SSO user information from the session
    clear_user_session

    # redirect to the logout page for SSO
    logout_url = PrismeUtilities.ssoi_logout_path
    raise 'SSO logout url is not properly configured.' unless logout_url
    redirect_to logout_url
  end


  api :GET, PrismeUtilities::RouteHelper.route(:roles_get_all_roles_path), 'Request all roles as HTML or JSON.'
  description %q{
Returns all the roles defined on the system.<br>
<br>Append .json to the end of the url to change the format away from html.
 }

  def get_all_roles
    @roles_hash = Roles::ALL_ROLES
    respond_to do |format|
      format.html # get_all_roles.html.erb
      format.json {render :json => @roles_hash}
    end
  end

  #sample invocation
  #http://localhost:3000/roles/get_ssoi_roles.json?id=cboden
  api :GET, PrismeUtilities::RouteHelper.route(:roles_get_ssoi_roles_path), 'Request all roles for a VA Single Sign on User user as HTML or JSON.'
  param :id, String, desc: 'The SSO user id as defined by the header HTTP_ADSAMACCOUNTNAME', required: true
  description %q{
Returns all the roles for an SSOi user.
<br>Append .json to the end of the url to change the format away from html.<br>
JSON keys are user => user_string, roles => roles_array, token => user_token.<br>

Not currently used in production, but helpful for debugging.
Does not support the isaac_db_uuid parameter, so being a modeler in for any isaac db will show that role.
}

  def get_ssoi_roles
    ssoi_user = params[:id]
    user = SsoiUser.fetch_user(ssoi_user)
    @roles_hash = {roles: [], token: 'Not Authenticated', type: 'ssoi'}

    if user
      @roles_hash[:roles] = user.roles.map(&:name)
      @roles_hash[:token] = build_user_token(user)
      @roles_hash[:user] = ssoi_user
      add_issac_dbs(@roles_hash, user)
    end

    respond_to do |format|
      format.html {render file: 'roles/user_roles'}
      format.json {render json: @roles_hash}
    end
  end

  #token for the current user
  api :GET, PrismeUtilities::RouteHelper.route(:roles_my_token_path), 'Request the role token for the current user as JSON, HTML or text.'
  formats ['json', 'html', 'text']
  desc = <<END_DESC
Displays the token for the currently logged in user.<br>Displays 'INVALID USER' if logged out.<br>
Append .json or .text to the end of the url to change the format away from html.
Try it!<br>
SSO: #{PrismeUtilities::RouteHelper.route(:roles_my_token_url, true)}
<br><br>
END_DESC
  unless PrismeUtilities.aitc_production?
    desc << "Local: #{PrismeUtilities::RouteHelper.route(:roles_my_token_url)}"
  end
  description desc

  def my_token
    @token = build_user_token prisme_user
    respond_to do |format|
      format.html #my_token.html.erb
      format.json {render json: {token: @token}}
      format.text {render text: @token}
    end
  end

  #sample invocation
  #http://localhost:3000/roles/get_user_roles.json?id=devtest@devtest.gov&password=devtest@devtest.gov
  #http://localhost:3000/roles/get_user_roles.json?id=cris@cris.com&password=cris@cris.com
  api :GET, PrismeUtilities::RouteHelper.route(:roles_get_user_roles_path), 'Request the roles for the given locally signed on user as JSON, HTML.'
  param :id, String, desc: 'The email address of the local user.', required: true
  param :password, String, desc: 'The password of the local user.', required: true
  description %q{
Gets the roles for a given locally signed on user.<br>
Append .json the end of the url to change the format away from html.<br>
JSON keys are user => user_string, roles => roles_array, token => user_token.<br>

Not currently used in production, but helpful for debugging.
Does not support the isaac_db_uuid parameter, so being a modeler in for any isaac db will show that role.
  }

  def get_user_roles
    user_id = params[:id]
    password = params[:password]
    user = User.find_by(email: user_id)
    authenticated = (!user.nil? && user.valid_password?(password))
    $log.info("The user #{user_id} tried to get roles but was not authenticated.") unless authenticated
    @roles_hash = {user: user_id, roles: [], token: 'Not Authenticated', type: 'devise'}

    if authenticated
      @roles_hash[:roles] = user.roles.map(&:name)
      @roles_hash[:token] = build_user_token(user)
      @roles_hash[:user] = user_id
      add_issac_dbs(@roles_hash, user)
    end

    respond_to do |format|
      format.html {render file: 'roles/user_roles'}
      format.json {render json: @roles_hash}
    end
  end


  # http://localhost:3000/roles/get_roles_by_token.json?token=%5B%22u%5Cf%5Cx8F%5CxB1X%5C%22%5CxC2%5CxEE%5CxFA%5CxE1%5Cx91%5CxBF3%5CxA9%5Cx16K%22%2C+%22~K%5CxC4%5CxEFXk%5Cx80%5CxB1%5CxA3%5CxF3%5Cx8D%5CxB1%5Cx7F%5CxBC%5Cx02K%22%2C+%22k%5Cf%5CxDC%5CxF7%5Cx19z%5Cx9C%5CxBA%5CxAF%5CxBF%5Cx83%5CxEE%5Cx15%5CxD9kN%22%5D
  api :GET, PrismeUtilities::RouteHelper.route(:roles_get_roles_by_token_path), 'Request the roles for the given token as JSON, HTML.'
  param :token, String, desc: 'The token for the given user.', required: true
  param :isaac_db_uuid, String, desc: 'An optional isaac database uuid.  Modeling roles are apropriately filtered.', required: false
  description %q{
Gets the roles for a given token.<br>
There will be a key called 'roles' pointing to an array of hashes containing role data.<br>
There will be a key called 'with_isaac_db_id' pointing to modeling roles by isaac db.<br>
There will be a key called 'token_parsed?' with the string 'true' or 'false'.<br>
There will be a key called 'type' with the value 'devise' or 'ssoi'.  Devise implies a local user.<br>
Each hash in the role array contains metadata about the role.  The most important key is the 'name' key which points<br>
to the name of the role.
Append .json the end of the url to change the format away from html.
  }

  def get_roles_by_token
    @token = params[:token]
    @isaac_db_uuid = params[:isaac_db_uuid]
    roles = []
    @roles_hash = {}
    @roles_hash[:roles] = roles
    deconstruct_user_token @token
    @roles_hash[:token_parsed?] = @parsed
    if (@parsed)
      user = User.find_by(email: @user_name) if @user_type.eql? PrismeUserConcern::DEVISE_USER.to_s
      user = SsoiUser.fetch_user(@user_name) if @user_type.eql? PrismeUserConcern::SSOI_USER.to_s
      $log.info("The user I found is #{user} with id #{user&.id}, the id in the token is #{@user_id}, the user type is #{@user_type}, token name is #{@user_name}")
      if (!user.nil? && user.id.eql?(@user_id))
        @roles_hash[:user] = @user_name
        @roles_hash[:type] = @user_type
        @roles_hash[:id] = @user_id
        add_issac_dbs(@roles_hash, user)
        user.roles.each do |role|
          role_string = role.name
          if (!@isaac_db_uuid.nil? && Roles::MODELING_ROLES.include?(role_string))
            roles << role if user.isaac_role?(role_string: role_string, isaac_db_id: @isaac_db_uuid)
          else
            roles << role
          end
        end
      else
        $log.warn("The ids in the token do not match the id found in the database! No roles!")
      end
    end
    respond_to do |format|
      format.html # get_roles_by_token.html.erb
      format.json {render :json => @roles_hash}
    end
  end

  private

  def add_issac_dbs(role_hash,user)
    return if user.nil?
    role_hash[:with_isaac_db_id] = user.get_all_isaac_db
  end

  def build_user_token(user)
    return 'INVALID USER' if user.nil?
    return 'INVALID USER' unless user.is_a? PrismeUserConcern
    id = user.id
    type = (user.is_a? SsoiUser) ? PrismeUserConcern::SSOI_USER : PrismeUserConcern::DEVISE_USER
    name = user.user_name
    token_hash = {}
    token_hash[:id] = id
    token_hash[:type] = type
    token_hash[:name] = name
    TokenSupport.instance.encrypt(unencrypted_string: token_hash.to_json.to_s, preamble: USER_PREAMBLE)
    #to decrypt:
    # JSON.parse TokenSupport.instance.decrypt(encrypted_string: TokenSupport.instance.jsonize_token( the_result))
  end

  def deconstruct_user_token(token)
    @parsed = true
    $log.debug("token is #{token}")
    begin
      result = TokenSupport.instance.decrypt(encrypted_string: token, preamble: USER_PREAMBLE)
      hash = JSON.parse result
      @user_id = hash[:id.to_s].to_i
      @user_type = hash[:type.to_s]
      @user_name = hash[:name.to_s]
    rescue Exception => ex
      $log.warn("I could not parse the incoming token, #{ex.message}")
      @parsed = false
    end

  end

  def ssl_configured_delegator?
    RolesController.ssl_configured?
  end

  def self.ssl_configured?
    #When changing the impl of this method below, rethink these lines in app_deployer_controller.rb
    #war_cookie_params[:prisme_roles_url] = URI(roles_get_roles_url).to_https if RolesController.ssl_configured?
    #war_cookie_params[:prisme_roles_url] = roles_get_roles_url unless RolesController.ssl_configured?
    false
    #true
    #java.lang.getSystemProperties.get("catilina.ssl_port")
    #!Rails.env.development?
  end

end
=begin
#Scratch for playing with tokens
token =  `curl "http://localhost:3000/roles/get_roles_token?id=cshupp@gmail.com&password=cshupp@gmail.com"`
puts "-->#{token}<--"
require 'faraday'

conn = Faraday.new(url: "http://localhost:3000/") do |faraday|
  faraday.request :url_encoded # form-encode POST params
  faraday.headers['Accept'] = 'application/text'
  faraday.adapter :net_http # make requests with Net::HTTP
end

params = {token: token}
#params = {token: token + "invalid crap"}
response = conn.get("roles/get_roles_token", params)
puts "\n\nNew Token:\n"
puts response.body
=end