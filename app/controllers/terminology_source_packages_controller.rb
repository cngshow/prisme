class TerminologySourcePackagesController < ApplicationController
  before_action :auth_registered

  def new
    @package = TerminologySourcePackage.new
    2.times { @package.terminology_source_contents.build }
  end

  # POST /terminology_package
  # POST /terminology_package.json
  def create
    @package = TerminologySourcePackage.new(terminology_source_package_params)
    @package.user = current_user.email

    respond_to do |format|
      if @package.save
        format.html { redirect_to @package, notice: 'Isaac database was successfully created.' }
        format.json { render :show, status: :created, location: @package }
      else
        format.html { render :new }
        format.json { render json: @package.errors, status: :unprocessable_entity }
      end
    end
  end

  private
  # Never trust parameters from the scary internet, only allow the white list through.
  def terminology_source_package_params
    params.require(:terminology_source_package).permit(:user, terminology_source_contents_attributes: [ :upload ])
  end

end
