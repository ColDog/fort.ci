require "fort_ci/serializers/serializer"

module FortCI
  class JobSerializer < BaseSerializer
    has_one :pipeline, if: :show_all?
    has_one :project, if: :show_all?, through: :pipeline

    attributes :id, :pipeline_id, :pipeline_stage, :key, :status, :commit, :branch, :worker, :created_at, :updated_at
    attribute :spec, if: :show_all?

    def show_all?
      instance_options[:show_all]
    end

  end
end
