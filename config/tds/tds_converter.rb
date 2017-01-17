site_string = File.open('c:\work\vets-lfs\VETS_Site_Table.csv', 'r').read

lines = site_string.split("\n")
lines.shift

hash = {}
hash[:SITES] = {}
lines.each do |l|
  data = l.split('|')
  hash[:SITES][data[0]] = {}
  hash[:SITES][data[0]][:GROUP_NAME] = data[1]
  hash[:SITES][data[0]][:MESSAGE_TYPE] = data[2]
  hash[:SITES][data[0]][:NAME] = data[3]
  hash[:SITES][data[0]][:TYPE] = data[4]
  hash[:SITES][data[0]][:VA_SITE_ID] = data[5]
end

sites = []
hash[:SITES].keys.each do |index|
 # sites << {'va_site_id' => hash[:SITES][index][:VA_SITE_ID].to_s,'name' => hash[:SITES][index][:NAME].to_s, 'site_type' => hash[:SITES][index][:TYPE].to_s, 'message_type' => hash[:SITES][index][:MESSAGE_TYPE].to_s}
  sites << {'va_site_id' => hash[:SITES][index][:VA_SITE_ID].to_s,'name' => hash[:SITES][index][:NAME].to_s, 'site_type' => hash[:SITES][index][:TYPE].to_s}
end
#to yaml is only available in rails, run in console not scratch.
File.open('C:\work\va-ctt\rails\rails_prisme\config\tds\site_data.yml','w') do |f| f.write sites.to_yaml end
#File.open('C:\temp\foo\va_groups.yml','w') do |f| f.write h.to_yaml end
original = YAML.load_file './config/tds/site_data_original.yml'
groups = {}
original[:SITES].keys.each do |site_id|
  gn = original[:SITES][site_id][:GROUP_NAME]
  next if gn.empty?
  groups[gn] ||= {}
  groups[gn][:member_sites] ||= []
  groups[gn][:member_sites] << original[:SITES][site_id][:VA_SITE_ID].to_i
end
g_to_yml = []
index = 1
groups.keys.each do |group_name|
  g_to_yml << {'id' => index, 'name' => group_name, 'member_sites' => groups[group_name][:member_sites], 'member_groups' => nil}
  index += 1
end
File.open('C:\work\va-ctt\rails\rails_prisme\config\tds\group_data.yml','w') do |f| f.write g_to_yml.to_yaml end

