require "fort_ci/models/model"

module FortCI
  class Pipeline < Model
    belongs_to :project, optional: true
    has_many :jobs

    serialize :event, JSON

    def definition_class
      @definition_class ||= definition.constantize
    end

    def status?(is)
      status && status.upcase == is.to_s.upcase
    end

    def run
      PipelineStageJob.new(pipeline: self).enqueue
    end

    def event
      @event ||= Event.new(super)
    end

  end
end
