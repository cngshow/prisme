class VaGroup < ActiveRecord::Base
  validates_uniqueness_of :name

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

  private
  def split_members(type)
    type.to_s.split(',').map(&:strip)
  end

  def get_member_groups(group_id:)
    split_members(VaGroup.where('id = ?)', group_id).first.member_groups)
  end
end

#load('./app/models/va_group.rb')

=begin

va_group
id    name          member_sites     member_groups
1     southeast     10,20,30          2,4
2     northeast     40,41             3
3     east          50                1

sites
10 florida
20 GA
30 south carolina
40 ny
41 nj
50 wi
60 nc

=end
