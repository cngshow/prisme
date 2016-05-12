module ServicesHelper
  PORT_RANGE = {min: 1, max: 9999, pattern: "\d*"}
  VALID_HOSTNAME = {pattern: '^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$'}
  NO_SPACES = {pattern: '^[\w|\.]+$'}
  URL_INPUT = {maxlength: 255, size: 75}

  def get_input_type(service_type, key, service_active_record = nil)
    hash = {}
    props = $SERVICE_TYPES[service_type][PrismeService::TYPE_PROPS]
    type = props.select {|t| t[PrismeService::TYPE_KEY].eql?(key)}.first[PrismeService::TYPE_TYPE]
    tooltip = props.select {|t| t[PrismeService::TYPE_KEY].eql?(key)}.first[PrismeService::TYPE_TOOLTIP]
    type = type.nil? ? 'text' : type
    hash[:type] = type
    hash[:required] = true
    hash[:title] = tooltip

    case type
      when PrismeService::TYPE_PASSWORD
        if (service_active_record)
          hash[:value] = service_active_record.properties_hash[key]
        end
      when PrismeService::TYPE_URL
        hash.merge!(URL_INPUT)
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
        service_exists = Service.exists?(service_type: type)
        valid_types << type unless service_exists
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
