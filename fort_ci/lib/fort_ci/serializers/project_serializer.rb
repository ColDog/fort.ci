require "fort_ci/serializers/serializer"

module FortCI
  class ProjectSerializer < BaseSerializer
    type :project
    attributes Project.column_names
    attributes :status
  end
end
