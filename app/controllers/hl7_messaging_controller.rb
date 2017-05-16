require './lib/hl7/hl7_message' #require me?
require './lib/hl7/discovery_diff' #require me Greg

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
    status_filter = params['status_filter']
    data = get_diff_data(detail_id: detail_id, status_filter: status_filter)
    headers = data[:headers]
    data.delete(:headers)
    vista_only, isaac_only, deltas = [],[],[]

    data.each_pair do |vuid, vals|
      if vals.is_a? Array
        # status is always the last column in the array so interpret the value
        vals.last[-1] = vals.last.last.to_s.eql?('0') ? 'Inactive' : 'Active'
        (vals.first.eql?(:left_only) ? vista_only : isaac_only) << Hash[headers.zip vals.last]
      else
        vals.each do |prop|
          diff = {vuid: vuid, designation: vals[:designation_name].to_s}
          unless prop.first.eql? :designation_name
            diff[:field_name] = prop.first.to_s
            diff[:vista_value] = prop.last.first.to_s
            diff[:isaac_value] = prop.last.last.to_s
            deltas << diff
          end
        end
      end
    end

    render json: {
        diffs: deltas,
        vista_only: vista_only,
        isaac_only: isaac_only,
        headers: headers
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
      format.text { render :text => csv }
      format.xml { render :xml => detail }
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
  def get_diff_data(detail_id:, status_filter:)
    require('./config/hl7/discovery_mocks/discovery_mock') #require me Greg
    discoveries = Dir.glob('./config/hl7/discovery_mocks/*.discovery')
    discovery = File.open(discoveries.sample, 'rb').read
    # reactions = File.open(discoveries.last, 'rb').read
    discovery_csv_string = HL7Messaging.discovery_hl7_to_csv(discovery_hl7: discovery)
    # reactions_csv_string = HL7Messaging.discovery_hl7_to_csv(discovery_hl7: reactions)
    discovery_csv = DiscoveryCsv.new(hl7_csv_string: discovery_csv_string, ignore_inactive: status_filter.eql?('active_only'))
    # reactions_csv = DiscoveryCsv.new(hl7_csv_string: reactions_csv_string)
    rdc = 1

    #this builds a reactants mock with the same number of columns
    discovery_mock = discovery_csv.diff_mock(right_diff_count: rdc, common_vuid_diff_count: 1, common_vuid_same_count: 1)

    # get the headers
    discovery_headers = discovery_csv.headers

    #get the diff hashes
    diff  = discovery_csv.fetch_diffs(discovery_csv: discovery_mock).diff
    diff.merge(headers: discovery_headers)
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