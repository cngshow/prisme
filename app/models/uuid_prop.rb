class UuidProp < ActiveRecord::Base
  validates_uniqueness_of :uuid
  self.primary_key = 'uuid'

  ISAAC_WAR_ID = 'warId'
  KOMET_WAR_ID = 'war_uuid'

  module Keys
    NAME = :name
    LAST_EDITED_BY = :last_edited_by
    LAST_READ_ON = :last_read_on

    ALL = [
        NAME,
        LAST_EDITED_BY,
        LAST_READ_ON,
    ]
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

    def uuid(uuid:)
      prop = UuidProp.find_or_create_by(uuid: uuid)
      prop.save_json_data!(key: Keys::LAST_READ_ON, value: Time.now.to_i)
      prop
    end

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
    hash.keys.each do |k| valid(k) end
    h = uuid_json_data
    h.merge!(hash)
    self.json_data = h.to_json
  end

  def uuid_json_data
    HashWithIndifferentAccess.new(JSON.parse(json_data)) rescue HashWithIndifferentAccess.new
  end

  def valid(key)
    raise ArgumentError.new("Please provide a valid UUID key. Valid keys are #{Keys::ALL.inspect}.") unless Keys::ALL.include?(key.to_sym)
  end
end

=begin
load('./app/models/uuid_prop.rb')
bo = UuidProp.uuid(uuid: 'bo')
bo.save_json_data(key: UuidProp::Keys::NAME, value: 'kma')
bo.get(key: UuidProp::Keys::NAME)

ma =  UuidProp.uuid(uuid: 'ma')
ma.save_json_hash(UuidProp::Keys::NAME => 'kool_aid', UuidProp::Keys::LAST_EDITED_BY => 'Cris')
=end