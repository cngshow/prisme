module ChecksumHelper
  def render_results_table(subsets:, sites:)
    @subset_request_hash = {}
    @site_request_array = []
    table = []
    striped = 0
    # [{"id":"Allergy","text":"Allergy","subsets":[{"id":"j2_3","text":"Reactions","icon":true,"li_attr":{"id":"j2_3"},"a_attr":{"href":"#","id":"j2_3_anchor"},"state":{"loaded":true,"opened":false,"selected":true,"disabled":false},"data":{},"parent":"Allergy"},{"id":"j2_4","text":"Reactants","icon":true,"li_attr":{"id":"j2_4"},"a_attr":{"href":"#","id":"j2_4_anchor"},"state":{"loaded":true,"opened":false,"selected":true,"disabled":false},"data":{},"parent":"Allergy"}]}]
    subsets.each do |subset|
      rows = []
      subset_id = subset['id']
      title = subset['text']
      subset['subsets'].each do |s|
        striped += 1
        subset_text = s['text']
        @subset_request_hash[title] ||= []
        @subset_request_hash[title] << subset_text
        sites.each do |site|
          site_id = site['id']
          site_name = site['text']
          rows << {site_id: site_id, site_name: site_name, subset_id: subset_id, subset_text: subset_text, striped: striped}
          @site_request_array << site_id
        end
      end
      table_rows = render_to_string partial: 'checksum_results_table_rows.html.erb', locals: {rows: rows}
      table_html = render_to_string partial: 'checksum_results_table.html.erb', locals: {title: title, rows: table_rows}
      table << table_html
    end
    table.join('<br><br>').html_safe
  end

  def view_checksum_detail(checksum_detail:)
    last = checksum_detail.checksum.nil?

    if last && checksum_detail.last_checksum
        ret = checksum_detail.last_checksum
    else
      last = false
      ret = checksum_detail
    end
    [ret, last]
  end
end
