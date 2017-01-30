class UuidProp < ActiveRecord::Base
  validates_uniqueness_of :uuid
  self.primary_key = 'uuid'

  ISAAC_WAR_ID = 'WarId'

  module Keys
    KOMET_NAME = :komet_name
    LAST_EDITED_BY = :last_edited_by
    LAST_READ_ON = :last_read_on

    ALL = [
        KOMET_NAME,
        LAST_EDITED_BY,
        LAST_READ_ON,
    ]
  end


  def self.uuid(uuid:)
    prop = UuidProp.find_or_create_by(uuid: uuid)
    prop.save_json_data!(key: Keys::LAST_READ_ON, value: Time.now.to_i)
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
    raise ArgumentError.new("Please provide a valid UUID key. Valid keys are #{Keys::ALL.inspect}.") unless Keys::ALL.include?(key)
  end
end

=begin
load('./app/models/uuid_prop.rb')
bo = UuidProp.uuid(uuid: 'bo')
bo.save_json_data(key: UuidProp::Keys::KOMET_NAME, value: 'kma')
bo.get(key: UuidProp::Keys::KOMET_NAME)
=end