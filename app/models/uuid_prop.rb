class UuidProp < ActiveRecord::Base
  validates_uniqueness_of :uuid
  self.primary_key = 'uuid'

  KOMET_NAME = :komet_name
  LAST_EDITED_BY = :last_edited_by
  LAST_READ_ON = :last_read_on

  UUID_KEYS = [
      KOMET_NAME,
      LAST_EDITED_BY,
      LAST_READ_ON,
  ]

  def self.uuid(uuid:)
    prop = UuidProp.find_or_create_by(uuid: uuid)
    prop.save_json_data!(key: LAST_READ_ON, value: Time.now.to_i)
    prop
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

  def uuid_json_data
    HashWithIndifferentAccess.new(JSON.parse(json_data)) rescue HashWithIndifferentAccess.new
  end

  def valid(key)
    raise ArgumentError.new("Please provide a valid UUID key. Valid keys are #{UUID_KEYS.inspect}.") unless UUID_KEYS.include?(key)
  end
end
