require "active_model_serializers"
require "sinatra/json"

ActiveModelSerializers.config.adapter = :json
