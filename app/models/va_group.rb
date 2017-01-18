class VaGroup < ActiveRecord::Base

  include InterestingColumnCompare

  validates_uniqueness_of :name
  validate :valid_sites?, :valid_groups?

  def initialize(hash)
    super()
    h = HashWithIndifferentAccess.new hash
    #sorting is done to ensure our simple eql? method works (see interesting_column_compare.rb)
    self.id,  self.name,  self.member_sites,  self.member_groups = h[:id], h[:name].strip, (h[:member_sites].nil? ? nil : h[:member_sites].uniq.sort.map(&:to_s).map(&:strip).join(',')), (h[:member_groups].nil? ? nil : h[:member_groups].map(&:to_s).uniq.sort.map(&:strip).join(','))
  end

  def all_sites
    ret = get_site_ids # my sites
    get_groups_activerecord.each do |g|
      ret = ret + g.get_site_ids
    end
    ret.uniq
  end

  def all_groups
    group_ids = get_group_ids
    ret = group_ids.deep_dup

    group_ids.inject(ret) do |array, g|
      nested = get_member_groups(group_id: g)
      unless nested.empty?
        nested.reject! { |id| array.include?(id) || array.include?(self.id) }
        ret = ret + nested
      end
    end

    ret
  end

  def all_groups_activerecord
    VaGroup.where('id in (?)', all_groups).all
  end

  def get_groups_activerecord
    VaGroup.where('id in (?)', get_group_ids).all
  end

  def get_sites_activerecord
    VaSite.where('va_site_id in (?)', get_site_ids).all
  end

  def all_sites_activerecord
    VaSite.where('va_site_id in (?)', all_sites).all
  end

  def get_site_ids
    split_members(self.member_sites)
  end

  def get_group_ids
    split_members(self.member_groups)
  end

  def valid_sites?
    sites = get_sites_activerecord
    site_ids = sites.map do |e| e.id end
    my_sites_array  = split_members(self.member_sites)
    valid = (sites.length == my_sites_array.length)
    errors.add(:site_errors, " sites are invalid!  Invalid sites were #{my_sites_array - site_ids}") unless valid
    valid
  end
  #if gr is the active record then:
  #gr.errors.messages[:group_errors]
  def valid_groups?
    groups = get_groups_activerecord
    group_ids = groups.map do |e| e.id end
    my_groups_array = split_members(self.member_groups)
    valid = (groups.length == my_groups_array.length)
    errors.add(:group_errors, " groups are invalid! Invalid groups were #{my_groups_array - group_ids}") unless valid
    valid
  end

  private
  def split_members(type)
    type.to_s.split(',').uniq.sort.map(&:strip)
  end

  def get_member_groups(group_id:)
    split_members(VaGroup.where('id = ?)', group_id).first.member_groups)
  end

end

#load('./app/models/va_group.rb')

=begin

va_group
id    name          member_sites     member_groups
1     southeast     10,20,30
2     northeast     40,41             1
3     east          50                1,2

sites
10 florida
20 GA
30 south carolina
40 ny
41 nj
50 wi
60 nc

=end
