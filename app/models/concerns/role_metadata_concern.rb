module RoleMetadataConcern
  extend ActiveSupport::Concern
  ISAAC_DB_UUIDS = 'isaac_db_uuids'

  module ClassMethods
    def user_id_col_name
      self.eql?(UserRoleAssoc) ? 'user_id' : 'ssoi_user_id'
    end
  end
  extend ClassMethods

  module Keys
    ISAAC_DBS = :isaac_db_uuids
  end
  VALID_KEYS = Keys.constants.map do |e| Keys.const_get(e) end

  #try
  #User.first.user_role_assocs.select do |ra| !ra.role_metadata.nil? end.first.get(key: UserRoleAssoc::Keys::ISAAC_DBS)
  def get(key:)
    valid(key)
    role_metadata_hash[key]
  end

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

  def valid(key)
    raise ArgumentError.new("Please provide a valid UUID key. Valid keys are #{VALID_KEYS}.") unless VALID_KEYS.include?(key.to_sym)
  end

  def role_metadata_hash
    HashWithIndifferentAccess.new(JSON.parse(role_metadata)) rescue HashWithIndifferentAccess.new
  end


end

=begin
u = User.first
ura = u.user_role_assocs
=end