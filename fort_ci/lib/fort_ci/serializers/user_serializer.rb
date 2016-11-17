require "fort_ci/serializers/serializer"

module FortCI
  class UserSerializer < BaseSerializer
    attributes :id, :name, :provider, :provider_id, :email, :username, :created_at, :updated_at
  end
end
