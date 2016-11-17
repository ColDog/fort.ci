module FortCI
  class Event
    attr_accessor :name, :project, :data

    def initialize(data={})
      @data = data
      @name = data[:name]
      @project = data[:project_id] ? Project.find(data[:project_id]) : nil
    end

    def execute
      return nil unless project.enabled_pipelines

      project.enabled_pipelines.each do |pipeline_definition|
        if pipeline_definition.constantize.trigger_when?(self)
          EventHandlerJob.new(event_data: self.data, definition_name: pipeline_definition).enqueue
        end
      end
    end

    def as_json(*)
      data
    end

  end
end
