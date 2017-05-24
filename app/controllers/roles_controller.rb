require 'uri'
require 'cgi'
class RolesController < ApplicationController

  resource_description do
    short 'Role APIs'
    formats ['json', 'html']
  end

  skip_after_action :verify_authorized
  skip_before_action :verify_authenticity_token
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
  }

  def get_ssoi_roles
    ssoi_user = params[:id]
    user = SsoiUser.fetch_user(ssoi_user)
    @roles_hash = {roles: [], token: 'Not Authenticated'}

    if user
      @roles_hash[:roles] = user.roles.map(&:name)
      @roles_hash[:token] = build_user_token(user)
      @roles_hash[:user] = ssoi_user
    end

    respond_to do |format|
      format.html # get_ssoi_roles.html.erb
      format.json {render :json => @roles_hash}
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
  }

  def get_user_roles
    user_id = params[:id]
    password = params[:password]
    user = User.find_by(email: user_id)
    authenticated = (!user.nil? && user.valid_password?(password))
    $log.info("The user #{user_id} tried to get roles but was not authenticated.") unless authenticated
    @roles_hash = {user: user_id, roles: [], token: 'Not Authenticated'}

    if authenticated
      @roles_hash[:roles] = user.roles.map(&:name)
      @roles_hash[:token] = build_user_token(user)
      @roles_hash[:user] = user_id
    end

    respond_to do |format|
      format.html # get_all_roles.html.erb
      format.json {render :json => @roles_hash}
    end
  end


  # http://localhost:3000/roles/get_roles_by_token.json?token=%5B%22u%5Cf%5Cx8F%5CxB1X%5C%22%5CxC2%5CxEE%5CxFA%5CxE1%5Cx91%5CxBF3%5CxA9%5Cx16K%22%2C+%22~K%5CxC4%5CxEFXk%5Cx80%5CxB1%5CxA3%5CxF3%5Cx8D%5CxB1%5Cx7F%5CxBC%5Cx02K%22%2C+%22k%5Cf%5CxDC%5CxF7%5Cx19z%5Cx9C%5CxBA%5CxAF%5CxBF%5Cx83%5CxEE%5Cx15%5CxD9kN%22%5D
  api :GET, PrismeUtilities::RouteHelper.route(:roles_get_roles_by_token_path), 'Request the roles for the given token as JSON, HTML.'
  param :token, String, desc: 'The token for the given user.', required: true
  description %q{
Gets the roles for a given token.  There will be a key called 'roles' pointing to an array of hashes containing role data.<br>
Each hash in the role array contains metadata about the role.  The most important key is the 'name' key which points<br>
to the name of the role.
Append .json the end of the url to change the format away from html.
  }

  def get_roles_by_token
    token = params[:token]
    roles = []
    @roles_hash = {}
    @roles_hash[:roles] = roles
    deconstruct_user_token token
    @roles_hash[:token_parsed?] = @parsed
    if (@parsed)
      user = User.find_by(email: @user_name) if @user_type.eql? PrismeUserConcern::DEVISE_USER.to_s
      user = SsoiUser.fetch_user(@user_name) if @user_type.eql? PrismeUserConcern::SSOI_USER.to_s
      $log.info("The user I found is #{user} with id #{user&.id}, the id in the token is #{@user_id}, the user type is #{@user_type}, token name is #{@user_name}")
      if (!user.nil? && user.id.eql?(@user_id))
        @roles_hash[:user] = @user_name
        @roles_hash[:type] = @user_type
        @roles_hash[:id] = @user_id
        user.roles.each do |role|
          roles << role
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

  #sample invocation
  # http://localhost:3000/roles/get_roles_token?id=cshupp@gmail.com&password=cshupp@gmail.com
  #not currently in routes.rb.  Unused as of now.
  def get_roles_token
    @user_id = params[:id]
    @password = params[:password]
    @token = params[:token]
    @token = nil if @token.eql?('')
    token_valid = true
    token_error = nil
    hash = nil
    if @token
      json = CipherSupport.instance.jsonize_token @token
      $log.debug("token is #{@token}")
      begin
        json = CipherSupport.instance.decrypt(encrypted_string: json)
        hash = JSON.parse json
      rescue Exception => ex
        token_valid = false
        $log.warn("An invalid token was recieved. The error is #{ex.message}")
        token_error = 'Invalid Token!'
        $log.error("Token parse failed! #{token_error}")
      end
      @user_id = hash['user'] if token_valid
      $log.debug("TOKEN hash is #{hash.inspect}")
      $log.debug("User from token is #{@user_id}")
    end
    $log.debug("About to fetch the roles for ID #{@user_id}")
    @token_hash = {}
    @roles_array = []
    user = User.find_by(email: @user_id)
    @authenticated = false
    @authenticated = user.valid_password?(@password) unless (user.nil?)
    @authenticated = true if token_valid #we assume validity with a parseable_token
    $log.info("The user #{@user_id} tried to get roles but was not authenticated.") unless @authenticated
    unless user.nil? || !@authenticated
      user.roles.each do |role|
        @roles_array << role[:name]
      end
    end
    @token_hash[:roles] = @roles_array
    @token_hash[:issue_time] = Time.now.to_i
    @token_hash[:user] = @user_id
    @token_hash[:denomination] = ['1 dollar', '5 dollars', '10 dollars', '20 dollars', '50 dollars', '100 dollars'].sample
    token_string = CipherSupport.instance.stringify_token CipherSupport.instance.encrypt(unencrypted_string: @token_hash.to_json.to_s)
    respond_to do |format|
      format.text {render :text => token_string} if token_valid
      format.text {render :text => token_error} unless token_valid
    end
    $log.debug(token_string)
    $log.debug(CipherSupport.instance.decrypt(encrypted_string: CipherSupport.instance.jsonize_token(token_string)))
  end

  private

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
    CGI::escape CipherSupport.instance.encrypt(unencrypted_string: token_hash.to_json.to_s)
    #to decrypt:
    # JSON.parse CipherSupport.instance.decrypt(encrypted_string: CipherSupport.instance.jsonize_token( the_result))
  end

  def deconstruct_user_token(token)
    @parsed = true
    $log.debug("token is #{token}")
    begin
      result = CipherSupport.instance.decrypt(encrypted_string: (CGI::unescape token))
      $log.debug(result)
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