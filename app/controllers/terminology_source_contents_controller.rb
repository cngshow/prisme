class TerminologySourceContentsController < ApplicationController
  before_action :set_terminology_source_content, only: [:show, :edit, :update, :destroy]
  skip_after_action :verify_authorized

  # GET /isaac_databases
  # GET /isaac_databases.json
  def index
    @terminology_source = TerminologySourceContent.order('created_at')
    # i = TerminologySourceContent.order('created_at')
  end

  # GET /isaac_databases/1
  # GET /isaac_databases/1.json
  def show
  end

  # GET /isaac_databases/new
  def new
    @terminology_source = TerminologySourceContent.new
  end

  # GET /isaac_databases/1/edit
  def edit
  end

  # POST /isaac_databases
  # POST /isaac_databases.json
  def create
    @terminology_source = TerminologySourceContent.new(terminology_source_content_params)

    respond_to do |format|
      if @terminology_source.save
        format.html { redirect_to @terminology_source, notice: 'Isaac database was successfully created.' }
        format.json { render :show, status: :created, location: @terminology_source }
      else
        format.html { render :new }
        format.json { render json: @terminology_source.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /isaac_databases/1
  # PATCH/PUT /isaac_databases/1.json
  def update
    respond_to do |format|
      if @terminology_source.update(terminology_source_content_params)
        format.html { redirect_to @terminology_source, notice: 'Isaac database was successfully updated.' }
        format.json { render :show, status: :ok, location: @terminology_source }
      else
        format.html { render :edit }
        format.json { render json: @terminology_source.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /isaac_databases/1
  # DELETE /isaac_databases/1.json
  def destroy
    @terminology_source.destroy
    respond_to do |format|
      format.html { redirect_to isaac_databases_url, notice: 'Isaac database was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_terminology_source_content
      @terminology_source = TerminologySourceContent.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def terminology_source_content_params
      params.require(:terminology_source_content).permit(:user, :upload)
    end
end
