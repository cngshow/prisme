require 'will_paginate/array'
require './lib/hl7/hl7_message'

class Hl7MessagingController < ApplicationController
  include ChecksumDiscoveryConcern
  include Hl7MessagingHelper
  include HL7Messaging
  before_action :can_deploy
  before_action :verify_hl7_engine, :except => :checksum_request_poll

  PREVIOUS_TAG = 'PREVIOUS'
  CURRENT_TAG = 'CURRENT'

  def checksum
    @nav_type = 'checksum'
    setup
    render :index
  end

  def discovery
    @nav_type = 'discovery'
    setup
    render :index
  end

  def discovery_diffs
    detail_id = params['detail_id'] # todo use this one day when we have an API
    data = get_diff_data(detail_id: detail_id)
    vista_only, isaac_only, deltas = [], [], []

    data.each_pair do |vuid, vals|
      if vals.is_a? Array
        vista_only << vals.last if vals.first.eql?(:left_only)
        isaac_only << vals.last if vals.first.eql?(:right_only)
      else
        diffs = []
        diff = {vuid: vuid, designation: vals[:designation_name]}
        vals.each do |prop|
          unless prop.first.eql? :designation_name
            hash_key = prop.first
            hash_val = prop.last
            prop_hash = {hash_key.to_sym => hash_val}
            diffs << prop_hash
          end
        end
        diff[:diffs] = diffs
        deltas << diff
      end
    end

    # diffs = [{:vuid=>:"4636847", :designation=>:SOAPS, :diffs=>[{:Allergy_Type=>[:OTHER, :OTHER_different]}, {:has_drug_class=>[:"", :_different]}]}]
    # vista = [[:"4538520", :"OTHER ALLERGY/ADVERSE REACTION", :OTHER, :"", :"", :"", :"", :"0"], [:"4538521", :IODINE, :DRUG, :"DE101|DX101|PH000", :IODINE, :"", :"", :"0"], [:"4538522", :IRONFILLINGS, :OTHER, :"", :"", :"", :"", :"0"], [:"4538987", :SPICES, :FOOD, :"", :"", :"", :"", :"1"], [:"4539033", :COSMETICS, :OTHER, :"", :"", :"MAKE-UP|MAKEUP", :"", :"1"], [:"4539335", :"RAW VEGETABLES", :FOOD, :"", :"", :"VEGETABLES, RAW", :"", :"1"], [:"4541166", :BETAHISTINE, :DRUG, :"", :"", :"BETAHISTINE 8 MG", :"", :"0"], [:"4636630", :"EGG SUBSTITUTES", :FOOD, :"", :"", :"", :"", :"1"], [:"4636659", :"CONTRAST MEDIA", :DRUG, :"DX201|DX109|DX000|DX102|DX200|DX100|DX101|DX202", :"IODOHIPPURATE SODIUM,I-131|METRIZAMIDE|OXTAFLUOROPROPANE|SINCALIDE|GALLIUM CITRATE,GA-67|PROPYLIODONE|EVANS BLUE|SODIUM PERTECHNETATE (Tc 99m)|MEDRONATE DISODIUM|IOHEXOL|IOPAMIDOL|IOCETAMIC ACID|XENON,XE-133|FANOLESOMAB|GADOPENTETATE DIMEGLUMINE|SODIUM CHROMATE,CR-51|IOPROMIDE|POTASSIUM PERCHLORATE|ISOSULFAN BLUE|ALBUMIN,IODINATED I-125 SERUM|IOTROLAN|FLUDEOXYGLUCOSE|INDOCYANINE GREEN|SELENOMETHIONINE,SE-75|IPODATE|CALDIAMIDE SODIUM|BARIUM SULFATE|GADOVERSETAMIDE|IODIXANOL|SODIUM PHOSPHATE,P-32|IOPANOIC ACID|SODIUM IODIDE|ALBUMIN,IODINATED I-131 SERUM|PERFLEXANE LIPID MICROSHERE|ADRENOCORTICOTROPIN (ACTH 1-18),I-125 (TYR)|IOXAGLATE|YTTERBIUM,YB-169|THALLOUS CHLORIDE,TL-201|DIATRIZOATE|IODINE|CYANOCOBALAMIN,CO-57|RUBIDIUM (Rb-82)|SUCCIMER|GADODIAMIDE|ALBUMIN,CHROMATED CR-51 SERUM|IODIPAMIDE MEGLUMINE|IOPHENDYLATE|MOLYBDENUM,MO-99|PERFLUTREN|FERROUS CITRATE,FE-59|DISOFENIN|INDIUM In 111 CAPROMAB PENDETIDE|IOTHALAMATE|TECHNETIUM Tc 99m|ROSE BENGAL|ALBUMIN|AMINOHIPPURATE|GLUCEPTATE|OXIDRONATE|PENTETATE|FIBRINOGEN", :"RADIO DYES|CT SCAN DYES|CT SCAN CONTRAST DYES|X-RAY DYES|RADIOLOGICAL CONTRAST DYES|RADIOLOGIC DYES|RADIO CONTRAST MEDIA|RADIATION CONTRASTS|CT CONTRAST DYES|DYE CONTRASTS|RADIOCONTRAST DYES|RADIOLOGY CONTRAST DYES|XRAY CONTRAST DYES|CT DYES|RADIOGRAPHIC CONTRAST DYES|RADIOLOGIC CONTRAST MEDIA|RADIOLOGY DYES|RADIOPAQUE CONTRAST DYES|RADIOPAQUE CONTRAST MEDIA|RADIOGRAPHIC DYES|CT CONTRAST MEDIA|RADIOACTIVE DYES|DIAGNOSTIC DYES|X-RAY CONTRAST MEDIA|RADIOLOGICAL DYES|X RAY DYES|RADIOLOGICAL/CONTRAST MEDIA|RADIOOPAQUE DYES|RADIO OPAQUE DYES|RADIOPAQUE DYES|RADIOLOGIC CONTRAST DYES|CONTRAST MATERIALS|CONTRAST MEDIUM|CAT SCAN DYES|RADIOLOGY CONTRAST MEDIA|RADIOGRAPHIC CONTRAST MEDIA|XRAY DYES|RADIOCONTRAST MEDIA|X-RAY CONTRAST DYES|CONTRAST MEDIA DYES|CONTRAST DYES|RADIOLOGICAL CONTRAST MEDIA|CONTRAST AGENTS", :"", :"1"], [:"4636664", :DATES, :FOOD, :"", :"", :"", :"", :"1"], [:"4636696", :"BRUSSELS SPROUTS", :FOOD, :"", :"", :"BRUSSEL SPROUTS", :"", :"1"], [:"7246488", :"NDS ALLERGY TEST: NUMBER ONE", :"DRUG, FOOD", :"", :"", :"", :"", :"0"]]
    # isaac = [[:"4636897_z9ugk05l_m", :"RAYON TAPE", :OTHER, :"", :"", :"RAYON TAPES", :"", :"1"]]

    # diff_rows = render partial: 'discovery_diffs_rows', locals: {rows: diffs}
    # vista_rows = render partial: 'discovery_diffs_vista_isaac_only', locals: {rows: vista}
    # isaac_rows = render partial: 'discovery_diffs_vista_isaac_only', locals: {rows: isaac}

    # g = render_to_string(partial: 'discovery_diffs_rows', formats: :html, layout: false, locals: { rows: [], app1: 'VistA', app2: 'ISAAC'})
    # b = 'stud'
    #deltas = deltas.paginate(:page => 1, :per_page => 5) #params[:page] for :page
    vista_only = vista_only.paginate(:page => 1, :per_page => 5)
    isaac_only = isaac_only.paginate(:page => 1, :per_page => 5)
    render json: {
        diff_rows: render_to_string(partial: 'discovery_diffs_rows', formats: :html, layout: false, locals: {rows: deltas}),
        vista_rows: render_to_string(partial: 'discovery_diffs_vista_isaac_only_rows', formats: :html, layout: false, locals: {rows: vista_only, app1: 'VistA', app2: 'ISAAC'}),
        isaac_rows: render_to_string(partial: 'discovery_diffs_vista_isaac_only_rows', formats: :html, layout: false, locals: {rows: isaac_only, app1: 'ISAAC', app2: 'VistA'})
    }
  end

  #http://localhost:3000/hl7_messaging/discovery_csv.txt?discovery_detail_id=10106_CURRENT
  #http://localhost:3000/hl7_messaging/discovery_csv.xml?discovery_detail_id=10106_PREVIOUS
  def discovery_csv
    id, detail = params[:discovery_detail_id].split('_') #id is the id of the current record. detail is either current or previous.
    #if detail is previous get the last detail
    detail_record = DiscoveryDetail.find(id) rescue DiscoveryDetail.new
    if (detail.eql? PREVIOUS_TAG)
      last_discovery = detail_record.last_discovery
      detail_record = last_discovery unless last_discovery.nil?
    end
    csv = detail_record.to_csv
    respond_to do |format|
      format.text {render :text => csv}
      format.xml {render :xml => detail}
    end
  end

  def hl7_messaging_results_table
    nav_type = params[:nav_type]
    history = boolean(params[:history])
    partial = "#{nav_type}_results_table"

    # repackage selected sites
    site_selections = JSON.parse(params[:site_selections])

    sites_arr = []
    site_selections.each do |s|
      sites_arr << s['id'].to_s
    end

    # repackage subset selections
    subset_selections = JSON.parse(params[:subset_selections])
    subset_hash = {}
    subset_selections.each do |group|
      subsets = []

      group['subsets'].each do |subset|
        subsets << subset['text']
      end
      subset_hash[group['id']] = subsets
    end

    session['hl7_request'] ||= {}
    session['hl7_request']['sites'] = sites_arr
    session['hl7_request']['subsets'] = subset_hash

    # build hl7_messaging request active records for display
    @results = HL7Messaging.build_checksum_discovery_ar(nav_type: nav_type, user: prisme_user.user_name, subset_hash: subset_hash, site_ids_array: sites_arr, save: !history)

    begin
      render partial: partial, locals: {history: history}
    rescue => ex
      $log.error('Strange error in hl7 result table')
      $log.error(ex.to_s)
      $log.error(ex.backtrace.join("\n"))
      raise ex
    end
  end

  def isaac_hl7
    row = params[:id]
    site_id, row_id, subset = row.split('_')

    render json: {isaac_hl7: 'isaac hl7 text'}
  end

  def discovery_request_poll
    hl7_poll_helper(klass: DiscoveryRequest, navtype: 'discovery') do |table_id, request|
      render partial: 'discovery_results_tbody', locals: {table_id: table_id, discovery_details: request.details}
    end
  end

  def checksum_request_poll
    hl7_poll_helper(klass: ChecksumRequest, navtype: 'checksum') do |table_id, request|
      render partial: 'checksum_results_tbody', locals: {table_id: table_id, checksum_details: request.details}
    end
  end

  def retrieve_sites
    sites = params[:sites]
    groups = params[:groups]
    all_sites = []
    VaGroup.find(groups.split(',')).each do |g|
      all_sites = all_sites + g.all_sites_activerecord
    end

    all_sites = all_sites + VaSite.find(sites.split(','))
    all_sites.uniq!
    render json: all_sites.as_json
  end

  def verify_hl7_engine
    running = HL7Messaging.running?
    flash_alert(message: 'The HL7 messaging engine is not running!  Please contact an administrator.') unless running
  end

  private
  def setup
    @active_subsets = subset_tree_data.to_json
    @group_tree = group_tree_data.to_json
    @site_tree = site_tree_data.to_json
  end

  public #todo don't check public in
  def get_diff_data(detail_id:)
    require('./config/hl7/discovery_mocks/discovery_mock') #require me Greg
    discoveries = Dir.glob('./config/hl7/discovery_mocks/*.discovery')
    reactants = File.open(discoveries.first, 'rb').read
    # reactions = File.open(discoveries.last, 'rb').read
    reactants_csv_string = HL7Messaging.discovery_hl7_to_csv(discovery_hl7: reactants)
    # reactions_csv_string = HL7Messaging.discovery_hl7_to_csv(discovery_hl7: reactions)
    reactants_csv = DiscoveryCsv.new(hl7_csv_string: reactants_csv_string)
    # reactions_csv = DiscoveryCsv.new(hl7_csv_string: reactions_csv_string)
    rdc = 40

    #this builds a reactants mock with the same number of columns
    reactants_mock = reactants_csv.diff_mock(right_diff_count: rdc, common_vuid_diff_count: 30, common_vuid_same_count: 50)

    # get the headers
    reactants_headers = reactants_csv.headers

    #get the diff hashes
    reactants_against_reactants_diff = reactants_csv.fetch_diffs(discovery_csv: reactants_mock).diff
    reactants_against_reactants_diff
  end

  def hl7_poll_helper(klass:, navtype:, &render_block)
    request_id = params[:request_id]
    domain = params[:domain]
    table_id = params[:table_id]

    if request_id.empty?
      request = HL7Messaging.build_checksum_discovery_ar(nav_type: navtype, user: prisme_user.user_name, subset_hash: session['hl7_request']['subsets'], site_ids_array: session['hl7_request']['sites'], save: false).select do
      |request|
        request.domain.eql?(domain)
      end.first
    else
      request = klass.send(:find, request_id)
    end
    begin
      render_block.call(table_id, request)
    rescue => ex
      $log.always('Strange error under #{navtype} poll')
      $log.always(ex.to_s)
      $log.always(ex.backtrace.join("\n"))
      raise ex
    end
  end

  def subset_tree_data
    # {"Allergy"=>["Reactions", "Reactants"], "Immunizations"=>["Immunization Procedure", "Skin Test"], "Pharmacy"=>["Medication Routes"], "Orders"=>["Order Status", "Nature of Order"], "TIU"=>["TIU Status", "TIU Doctype", "TIU Role", "TIU SMD", "TIU Service", "TIU Setting", "TIU Titles"], "Vitals"=>["Vital Types", "Vital Categories", "Vital Qualifiers"]}

    subset_root = {id: 'subset_root', text: 'Subsets', icon: 'fa fa-sitemap', state: {opened: true}, children: []}
    subsets = active_subsets
    subsets.each_pair do |subset, children|
      g = {id: subset, text: subset, icon: 'fa fa-object-group', children: children}
      subset_root[:children] << g
    end
    subset_root
  end

  def group_tree_data
    group_root = {id: 'group_root', text: 'Groups', icon: 'fa fa-sitemap', state: {opened: true}, children: []}

    groups = VaGroup.all
    groups.each do |group|
      g = {id: "#{group.class.to_s}_#{group.id}", text: group.name, a_attr: {member_sites: group.member_sites, member_groups: group.member_groups}, icon: 'fa fa-object-group'}
      group_root[:children] << g
    end
    group_root
  end

  def site_tree_data
    site_root = {id: 'site_root', text: 'Individual Sites', icon: 'fa fa-hospital-o', state: {opened: true}, children: []}

    sites = VaSite.all
    sites.each do |site|
      s = site.as_json
      s['id'] = "#{site.class.to_s}_#{site.va_site_id}"
      s['text'] = "#{site.va_site_id} - #{site.name}"
      s['site_type'] = "#{site.site_type}" #todo do we need this?
      s['message_type'] = "#{site.message_type}" #todo do we need this?
      s['li_attr'] = {'data-site_type': "#{site.site_type}", 'class': 'va_site'}
      site_root[:children] << s
    end
    site_root
  end
end

=begin
load('./app/controllers/hl7_messaging_controller.rb')
=end