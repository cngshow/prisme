class ServicesController < ApplicationController
  before_action :set_service, only: [:show, :edit, :update, :destroy]
  before_action :any_administrator, except: [:all_services_as_json]
  skip_after_action :verify_authorized, only: [:all_services_as_json]
  skip_before_action :verify_authenticity_token, only: [:all_services_as_json]

  # GET /services
  # GET /services.json
  def index
    @services = Service.all
  end

  # GET /services/1
  # GET /services/1.json
  def show
  end

  # GET /services/new
  def new
    @service = Service.new
  end

  # GET /services/1/edit
  def edit
  end

  # POST /services
  # POST /services.json
  def create
    @service = Service.new(service_params)
    prep_props_for_save

    respond_to do |format|
      if @service.save
        format.html { redirect_to @service, notice: 'Service was successfully created.' }
        format.json { render :show, status: :created, location: @service }
      else
        messages = ['Create Failed!']
        messages << errors_to_flash(@service.errors)
        flash.now[:error] = render_to_string(:partial => 'application/bulleted_flash_single_header', :locals => {:messages => messages }) unless @service.errors.blank?
        @service_type = @service.service_type
        format.html { render :new, locals: {failure: true} }
        format.json { render json: @service.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /services/1
  # PATCH/PUT /services/1.json
  def update
    respond_to do |format|
      prep_props_for_save

      if @service.update(service_params)
        format.html { redirect_to @service, notice: 'Service was successfully updated.' }
        format.json { render :show, status: :ok, location: @service }
      else
        messages = ['Update Failed!']
        messages << errors_to_flash(@service.errors)
        flash.now[:error] = render_to_string(:partial => 'application/bulleted_flash_single_header', :locals => {:messages => messages }) unless @service.errors.blank?
        format.html { render :edit }
        format.json { render json: @service.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /services/1
  # DELETE /services/1.json
  def destroy
    @service.destroy
    respond_to do |format|
      format.html { redirect_to services_url, notice: 'Service was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def render_props
    @service_type = params[:service_type]
    #render partial: services_render_props_path #WTF??!!??  This doesn't work when a context is set (in a war file)
    render partial: 'services/render_props'
  end

  #sample invocation
  #http://localhost:3000/services/all_services_as_json.json?security_token=%5B%22u%5Cf%5Cx92%5CxBC%5Cx17%7D%5CxD1%5CxE4%5CxFB%5CxE5%5Cx99%5CxA3%5C%22%5CxE8%5C%5CK%22%2C+%22%3E%5Cx16%5CxDE%5CxA8v%5Cx14%5CxFF%5CxD2%5CxC6%5CxDD%5CxAD%5Cx9F%5Cx1D%5CxD1cF%22%5D
  def all_services_as_json
    security_token = params['security_token']
    if (TokenSupport.instance.valid_security_token?(token: security_token))
      render json: Service.get_all_services_props
    else
      render json: {token_valid?: false}
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_service
    @service = Service.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def service_params
    params.require(:service).permit(:name, :description, :service_type, service_properties_attributes: [:id, :key, :value])
  end

  def prep_props_for_save
    service = params['service']
    service_type = service['service_type']
    service_type_props = $SERVICE_TYPES[service_type][PrismeService::TYPE_PROPS]

    if (@service.id?)
      props = service['service_properties_attributes']
      props.each do |p|
        order_idx = p[0].to_i
        value = p[1][PrismeService::TYPE_VALUE]

        service_type_props.each do |prop|
          if prop[PrismeService::TYPE_ORDER_IDX] == order_idx
            if (prop[PrismeService::TYPE_TYPE].eql?(PrismeService::TYPE_PASSWORD))
              value = CipherSupport.instance.encrypt(unencrypted_string: value)
            elsif prop[PrismeService::TYPE_TYPE].eql?(PrismeService::TYPE_URL)
              # ensure that there are no spaces
              value = value.split.first
              #remove all trailing slashes
              while (value[-1].eql?('/')) do
                value = value.chop
              end
            end
            break
          end
        end
        p[1][PrismeService::TYPE_VALUE] = value.strip
      end
    else
      props = params[PrismeService::TYPE_PROPS]
      order_idx = nil
      props.each_pair do |k, v|
        prop = @service.service_properties.build

        service_type_props.each do |p|
          order_idx = p['order_idx']
          if p[PrismeService::TYPE_KEY].eql?(k)
            if p[PrismeService::TYPE_TYPE].eql?(PrismeService::TYPE_PASSWORD)
              v = CipherSupport.instance.encrypt(unencrypted_string: v)
            elsif p[PrismeService::TYPE_TYPE].eql?(PrismeService::TYPE_URL)
              while (v[-1].eql?('/')) do
                v = v.chop
              end
            end
            break
          end
        end
        prop.key = k.strip
        prop.value = v.strip
        prop.order_idx = order_idx
      end
    end
  end
end
