json.array!(@terminology_source) do |terminology_source_content|
  json.extract! terminology_source_content, :id, :user
  json.url terminology_source_content_url(terminology_source_content, format: :json)
end
