require "fort_ci/serializers/serializer"

module SimpleCi
  class ProjectSerializer < BaseSerializer
    type :project
    attributes Project.column_names
    attributes :status
  end
end
