module ServicesHelper
  TYPE_PASSWORD='password'
  TYPE_URL='url'
  TYPE_NUMBER='number'

  #returns a password field or textfield
  def prop_input(p)
    case p['type']
      when TYPE_PASSWORD
        password_field_tag 'props[' + p['key']+']', nil, required: true
      when TYPE_URL
        return url_field_tag 'props[' + p['key']+']', nil, required: true
      when TYPE_NUMBER
        return number_field_tag 'props[' + p['key']+']',nil, in: 1..9999, required: true
      else
        return text_field_tag 'props[' + p['key']+']', nil, required: true, pattern: '^\w+$', title: 'No space allowed'
    end
  end

  def fetch_types
    types = $SERVICE_TYPES.keys
    valid_types = []
    types.each do |type|
      if($SERVICE_TYPES[type]['singleton'])
        valid_types << type unless Service.exists?(service_type: type)
      else
        valid_types << type
      end
    end
    valid_types
  end

  def get_label(type, key)
    props = $SERVICE_TYPES[type]['props']
    prop = props.select {|p| p['key'].eql?(key)}
    label = prop.first['label']
    label
  end
end
