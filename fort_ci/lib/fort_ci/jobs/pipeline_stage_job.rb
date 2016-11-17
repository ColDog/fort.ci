require "fort_ci/event"
require "worker"

module FortCI
  class PipelineStageJob < Worker::Job
    attr_reader :pipeline, :definition, :event

    def initialize(data={})
      @pipeline = data[:pipeline]
      @pipeline = Pipeline.find(data[:pipeline_id]) if data[:pipeline_id]
      @definition = pipeline.definition_class.new(pipeline, pipeline.event)
      @event = pipeline.event
    end

    def serialize
      JSON.generate({pipeline_id: pipeline.id})
    end

    def perform
      if pipeline.status?(:failed) || pipeline.status?(:complete)
        # pipeline has already been marked as failing or complete
        return
      end

      if last_stage_failed?
        # fail the pipeline if it's failing
        complete_pipeline :failed
        return
      end

      if last_stage_pending?
        # nothing to do here, still waiting on some jobs to come through
        return
      end

      # if we've gotten here all the checks are passing and we can move onto the next stage

      if !next_stage.present? && !last_stage_pending?
        # no next stage, pipeline is complete
        complete_pipeline :successful
        return
      end

      # set the stage for the execution to have this stage as it's state. If the execution fails, the stage will not be
      # saved, since save is only called in the on_success method.
      pipeline.stage = next_stage
      update_status :pending

      # run the next stage
      execute(next_stage)

      if !last_stage_pending?
        # no jobs were created during the this freshly run stage, therefore everything is done!
        complete_pipeline :successful
      end
    end

    def execute(this_stage)
      begin
        definition.send(this_stage)
      rescue Exception => e
        pipeline.update!(status: 'ERROR', error: e.message)
        raise e
      end
    end

    def on_success
      pipeline.save!
    end

    def complete_pipeline(status)
      # run through all the ensured stages and execute them.
      definition.class.ensure_stages.each do |ensured_stage|
        # will fail the job if an error is raised
        execute(ensured_stage)
      end
      update_status status
    end

    def next_stage
      @next_stage ||= begin
        if pipeline.stage
          cur_idx = definition.class.stages.find_index { |st| st == pipeline.stage.downcase.to_sym }
          definition.class.stages[cur_idx + 1]
        else
          definition.class.stages[0]
        end
      end
    end

    def update_status(status)
      pipeline.status = status.to_s.upcase
    end

    def last_stage_failed?
      Job.where(
          'pipeline_id = ? AND pipeline_stage = ? AND (status = "FAILED" OR status = "CANCELLED")',
          pipeline.id, pipeline.stage
      ).exists?
    end

    def last_stage_pending?
      Job.where(
          'pipeline_id = ? AND pipeline_stage = ? AND (status = "QUEUED" OR status = "PENDING")',
          pipeline.id, pipeline.stage
      ).exists?
    end

  end
end
