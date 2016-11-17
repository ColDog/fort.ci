require "fort_ci/serializers/serializer"

module FortCI
  class PipelineSerializer < BaseSerializer
    has_many :jobs, if: :show_all?
    has_one :project, if: :show_all?

    attributes Pipeline.column_names

    def show_all?
      instance_options[:show_all]
    end

  end
end
