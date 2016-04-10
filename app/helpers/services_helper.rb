module ServicesHelper
  PORT_RANGE = {min: 1, max: 9999, pattern: "\d*"}
  NO_SPACES = {pattern: '^[\w|\.]+$',title: 'No space allowed'}

  def get_input_type(service_type, key)
    hash = {}
    props = $SERVICE_TYPES[service_type][PrismeService::TYPE_PROPS]
    type = props.select {|t| t[PrismeService::TYPE_KEY].eql?(key)}.first[PrismeService::TYPE_TYPE]
    type = type.nil? ? 'text' : type
    hash[:type] = type
    hash[:required] = true

    case type
      when PrismeService::TYPE_PASSWORD
      #   only type is needed
      when PrismeService::TYPE_URL
      #   only type is needed
      when PrismeService::TYPE_NUMBER
        hash.merge!(PORT_RANGE)
      else
        hash.merge!(NO_SPACES)
    end
    hash
  end

  def fetch_types
    types = $SERVICE_TYPES.keys
    valid_types = []
    types.each do |type|
      if ($SERVICE_TYPES[type]['singleton'])
        valid_types << type unless Service.exists?(service_type: type)
      else
        valid_types << type
      end
    end
    valid_types
  end

  def get_label(type, key)
    props = $SERVICE_TYPES[type][PrismeService::TYPE_PROPS]
    prop = props.select { |p| p[PrismeService::TYPE_KEY].eql?(key) }
    prop.first['label']
  end

  def is_disabled?(service_type)
    Service.where(service_type: service_type).count == 1
  end
end
