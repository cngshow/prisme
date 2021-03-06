class UuidProp < ActiveRecord::Base
  validates_uniqueness_of :uuid
  validates_presence_of :uuid
  self.primary_key = 'uuid'

  ISAAC_WAR_ID = 'warId'
  ISAAC_DB_ID = 'isaacDbId'
  KOMET_WAR_ID = 'war_uuid'
  WAR_UUID_SELECTOR = ->(uuid_prop, uuid) do  uuid_prop.uuid.eql?(uuid) end
  ISAAC_DB_UUID_SELECTOR = -> (uuid_prop, uuid) do uuid_prop.get(key: UuidProp::Keys::ISAAC_DB_ID).eql?(uuid) end

  module Keys
    NAME = :uuid_name
    DESCRIPTION = :uuid_description
    LAST_EDITED_BY = :uuid_last_edited_by
    DEPENDENT_UUID = :uuid_dependent
    STATE = :uuid_state
    TIME = :uuid_time
    ISAAC_DB_ID = :isaac_db_id
  end

  class << self
    #put class methods here...
    def cleanup(older_than_in_days = 90)
      begin
        older_than_in_days = older_than_in_days.days.ago
        $log.info("Cleaning up all records in uuid prop table older than #{older_than_in_days}.")
        cnt = UuidProp.where('updated_at < ?', *[older_than_in_days]).delete_all
        $log.info("#{cnt} uuid props deleted.")
      rescue => ex
        $log.warn("Cleanup in uuid prop table failed. #{ex}")
        $log.warn(ex.backtrace.join("\n"))
      end
      cnt
    end

    def uuid(uuid:, dependent_uuid: nil, state: nil, isaac_db_id: nil)
      if uuid
        prop = UuidProp.find_or_create_by(uuid: uuid)
        last_certain_update = prop.get(key: Keys::TIME).to_i #converts nil to zero
        now = Time.now.to_i
        hash = {}
        hash[Keys::TIME] = now if ((now - last_certain_update) > 1.day.seconds.to_i)
        hash[Keys::DEPENDENT_UUID] = dependent_uuid if dependent_uuid
        hash[Keys::STATE] = state if state
        hash[Keys::ISAAC_DB_ID] = isaac_db_id if isaac_db_id
        prop.save_json_hash!(hash)
        prop
      end
    end

    #UuidProp.corresponding_issac_uuids(uuid: u, &UuidProp::WAR_UUID_SELECTOR)
    #UuidProp.corresponding_issac_uuids(uuid: u, &UuidProp::ISAAC_DB_UUID_SELECTOR)
    #Pull the name sample:
    #UuidProp.corresponding_issac_uuids(uuid: iu, &UuidProp::ISAAC_DB_UUID_SELECTOR).first.get(key: UuidProp::Keys::NAME)
    def corresponding_issac_uuids(uuid:, &block)
      props = UuidProp.all.to_a.select do |u| !u.get(key: UuidProp::Keys::ISAAC_DB_ID).nil? end
      rval = []
      props.each do |u|
        rval << u if block.call(u, uuid)
      end
      rval
    end

  end
#UuidProp.uuid(uuid: cris).running_dependency?

  def running_dependency?
    UuidProp.all.each do |uuid_prop|
      return uuid_prop.get(key: Keys::NAME) if ( (uuid_prop.get(key: Keys::DEPENDENT_UUID).eql?(uuid)) && uuid_prop.get(key: Keys::STATE).eql?(TomcatConcern::RUNNING_STATE))
    end
    return false
  end

  def save_json_hash(**hash)
    update_json_hash(hash)
    save
  end

  def save_json_hash!(**hash)
    update_json_hash(hash)
    save!
  end

  def save_json_data(key:, value:)
    update_json(key, value)
    save
  end

  def save_json_data!(key:, value:)
    update_json(key, value)
    save!
  end

  def get(key:)
    valid(key)
    uuid_json_data[key]
  end

  private
  def update_json(key, value)
    valid(key)
    h = uuid_json_data
    h[key] = value
    self.json_data = h.to_json
  end

  def update_json_hash(**hash)
    hash.keys.each do |k|
      valid(k)
    end
    h = uuid_json_data
    h.merge!(hash)
    self.json_data = h.to_json
  end

  def uuid_json_data
    HashWithIndifferentAccess.new(JSON.parse(json_data)) rescue HashWithIndifferentAccess.new
  end

  def valid(key)
    valid_keys = Keys.constants.map do |e| Keys.const_get(e) end
    raise ArgumentError.new("Please provide a valid UUID key. Valid keys are #{valid_keys}.") unless valid_keys.include?(key.to_sym)
  end
end

=begin
load('./app/models/uuid_prop.rb')
bo = UuidProp.uuid(uuid: 'bo')
bo.save_json_data(key: UuidProp::Keys::NAME, value: 'kma')
bo.get(key: UuidProp::Keys::NAME)

ma =  UuidProp.uuid(uuid: 'ma')
ma.save_json_hash(UuidProp::Keys::NAME => 'kool_aid', UuidProp::Keys::LAST_EDITED_BY => 'Cris')

UuidProp.destroy_all


a = UuidProp.all.to_a
a.first.save_json_data(key: UuidProp::Keys::NAME, value: 'I love ponies')
a.first.save_json_data(key: UuidProp::Keys::DESCRIPTION, value: 'I love Greg')
a.last.save_json_data(key: UuidProp::Keys::NAME, value: 'I want pizza')
a.last.save_json_data(key: UuidProp::Keys::DESCRIPTION, value: 'I want Cris')
a.first.get(key: UuidProp::Keys::DESCRIPTION)
      props = UuidProp.all.to_a.select do |u| !u.get(key: UuidProp::Keys::ISAAC_DB_ID).nil? end

UuidProps.isaac_db_uuid.to_war_uuid(db_uuid: props.first.get(key: UuidProp::Keys::ISAAC_DB_ID)
=end