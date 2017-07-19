module RoleMetadataConcern
  extend ActiveSupport::Concern
  ISAAC_DB_UUIDS = 'isaac_db_uuids'

  module ClassMethods
    def user_id_col_name
      self.eql?(UserRoleAssoc) ? 'user_id' : 'ssoi_user_id'
    end
  end
  extend ClassMethods

  def fetch_metadata
    role_metadata ? JSON.parse(role_metadata) : nil
  end

  def add_isaac_db_uuid(uuid)
    data = fetch_metadata
    if data
      if data.has_key?(ISAAC_DB_UUIDS)
        (data[ISAAC_DB_UUIDS] << uuid).uniq!
      else
        data[ISAAC_DB_UUIDS] = [uuid]
      end
    else
      data = {ISAAC_DB_UUIDS => [uuid]}
    end
    write_metadata! data
  end

  def remove_isaac_db_uuid(uuid)
    if has_isaac_uuid?(uuid)
      data = fetch_metadata
      data[ISAAC_DB_UUIDS].delete(uuid)
      write_metadata! data
    end
  end

  def has_isaac_uuid?(uuid)
    data = fetch_metadata
    uuids = []

    if data && data.has_key?(ISAAC_DB_UUIDS)
      uuids = data[ISAAC_DB_UUIDS]
    end
    uuids.include? uuid
  end

  private
  def write_metadata(hash)
    update_attributes(role_metadata: hash.to_json)
  end

  def write_metadata!(hash)
    update_attributes!(role_metadata: hash.to_json)
  end
end

=begin
u = User.first
ura = u.user_role_assocs
=end