require "fort_ci/serializers/serializer"

module SimpleCi
  class TeamSerializer < BaseSerializer
    attributes Team.column_names
  end
end
