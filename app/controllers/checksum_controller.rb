class ChecksumController < ApplicationController
  include ChecksumDiscoveryConcern
  include ChecksumHelper
  before_action :can_deploy


  def index
    @active_subsets = subset_tree_data.to_json
    @group_tree = group_tree_data.to_json
    @site_tree = site_tree_data.to_json
  end

  def subset_tree_data
    # {"Allergy"=>["Reactions", "Reactants"], "Immunizations"=>["Immunization Procedure", "Skin Test"], "Pharmacy"=>["Medication Routes"], "Orders"=>["Order Status", "Nature of Order"], "TIU"=>["TIU Status", "TIU Doctype", "TIU Role", "TIU SMD", "TIU Service", "TIU Setting", "TIU Titles"], "Vitals"=>["Vital Types", "Vital Categories", "Vital Qualifiers"]}

    subset_root = {id: 'subset_root', text: 'Subsets', icon: "fa fa-sitemap", state: {opened: true}, children: []}
    subsets = active_subsets
    subsets.each_pair do |subset, children|
      g = {id: subset, text: subset, icon: 'fa fa-object-group', children: children}
      subset_root[:children] << g
    end
    subset_root
  end

  def checksum_results_table
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

    # build checksum request active records for display
    @checksum_results = HL7Messaging.build_task_active_record(user: prisme_user.user_name, subset_hash: subset_hash, site_ids_array: sites_arr)
    render partial: 'checksum_results_table'
  end

  def checksum_request_poll
    checksum_request_id = params[:checksum_req_id]
    cr = ChecksumRequest.find(checksum_request_id)
    render partial: 'checksum_results_tbody', locals: {checksum_details: cr.checksum_details}
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
    site_root = {id: 'site_root', text: 'Individual Sites', icon: 'fa fa-hospital-o', state: {closed: true}, children: []}

    sites = VaSite.all
    sites.each do |site|
      s = site.as_json
      s['id'] = "#{site.class.to_s}_#{site.va_site_id}"
      s['text'] = "#{site.va_site_id} - #{site.name}"
      site_root[:children] << s
    end
    site_root
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
end
