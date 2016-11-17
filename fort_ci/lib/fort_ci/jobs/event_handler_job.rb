require "fort_ci/event"
require "fort_ci/worker"

module FortCI
  class EventHandlerJob < Worker::Job

    def initialize(data={})
      @event_data = HashWithIndifferentAccess.new(data[:event_data])
      @definition_name = data[:definition_name]
    end

    def perform
      definition = eval(@definition_name)
      event = Event.new(@event_data)

      # check this definition and see if it should run on this event.
      unless definition.trigger_when?(event)
        return
      end

      pipeline = Pipeline.create!(
          project_id: event.project.id,
          status: 'STARTING',
          event: event.data,
          definition: @definition_name,
      )

      PipelineStageJob.new(pipeline: pipeline).enqueue
    end

  end
end
