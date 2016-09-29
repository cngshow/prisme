require 'uri'

class RolesController < ApplicationController

  skip_after_action :verify_authorized
  skip_before_action :verify_authenticity_token
  force_ssl if: :ssl_configured_delegator? #,port: 8443

  def sso_logout
    # remove the SSO user information from the session
    clean_roles_session

    # redirect to the logout page for SSO
    logout_url = PrismeUtilities.ssoi_logout_path
    redirect_to logout_url # external url
  end

  #http://localhost:3000/roles/get_ssoi_roles.json?id=cboden
  def get_ssoi_roles
    @ssoi_user = params[:id]
    $log.debug("About to fetch the ssoi roles for ID #{@ssoi_user}")
    hash = SsoiUser.user_and_roles(@ssoi_user)
    user = hash[:user]
    @roles_array = hash[:roles]
    $log.debug("The roles are #{@roles_array}")
    @roles_hash = {}
    @roles_hash[:roles] = @roles_array
    @roles_hash[:token] = build_user_token user
    respond_to do |format|
      format.html # get_ssoi_roles.html.erb
      format.json { render :json => @roles_hash }
    end
  end

  #sample invocation
  #http://localhost:3000/roles/get_roles.json?id=devtest@devtest.gov&password=devtest@devtest.gov
  def get_roles
    @user_id = params[:id]
    @password = params[:password]
    $log.debug("About to fetch the roles for ID #{@user_id}")
    @roles_array = []
    user = User.find_by(email: @user_id)
    @authenticated = false
    @authenticated = user.valid_password?(@password) unless user.nil?
    $log.info("The user #{@user_id} tried to get roles but was not authenticated.") unless @authenticated
    unless (user.nil? || !@authenticated)
      user.roles.each do |role|
        @roles_array << role
      end
    end
    @roles_hash = {}
    @roles_hash[:roles] = @roles_array
    @roles_hash[:token] = build_user_token user if @authenticated
    @roles_hash[:token] = "Not Authenticated" unless @authenticated
    respond_to do |format|
      format.html # get_roles.html.erb
      format.json { render :json => @roles_hash }
    end
  end

  #sample invocation
  # http://localhost:3000/roles/get_roles_token?id=cshupp@gmail.com&password=cshupp@gmail.com
  def get_roles_token
    @user_id = params[:id]
    @password = params[:password]
    @token = params[:token]
    @token = nil if @token.eql?('')
    token_valid = true
    token_error = nil
    hash = nil
    if (@token)
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
      format.text { render :text =>  token_string} if token_valid
      format.text { render :text =>  token_error} unless token_valid
    end
    $log.debug(token_string)
    $log.debug(CipherSupport.instance.decrypt(encrypted_string: CipherSupport.instance.jsonize_token(token_string)))
  end

  private

  def build_user_token(user)
    return "INVALID USER" if user.nil?
    return "INVALID USER" unless user.is_a? PrismeUserConcern
    id = user.id
    type = (user.is_a? SsoiUser) ? PrismeUserConcern::SSOI_USER : PrismeUserConcern::DEVISE_USER
    name = user.user_name
    token_hash = {}
    token_hash[:id] = id
    token_hash[:type] = type
    token_hash[:id] = name
    CipherSupport.instance.stringify_token CipherSupport.instance.encrypt(unencrypted_string: token_hash.to_json.to_s)
    #to decrypt:
    # JSON.parse CipherSupport.instance.decrypt(encrypted_string: CipherSupport.instance.jsonize_token( the_result))
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