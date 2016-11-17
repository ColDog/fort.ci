require "fort_ci/serializers/serializer"

module FortCI
  class TeamSerializer < BaseSerializer
    attributes Team.column_names
  end
end
