require "sinatra/base"
require "active_model_serializers"

ActiveModelSerializers.config.adapter = :json

module Sinatra
  module JSON

    def json(resource, options={})
      content_type 'application/json'
      status = options[:status] || 200
      result = ActiveModelSerializers::SerializableResource.new(resource, options).to_json
      halt status, result
    end

  end
end
