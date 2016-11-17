require "fort_ci/serializers/serializer"

module SimpleCi
  class UserSerializer < BaseSerializer
    attributes :id, :name, :provider, :provider_id, :email, :username, :created_at, :updated_at
  end
end
