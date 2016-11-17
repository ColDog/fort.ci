module SimpleCi
  class PipelineDefinition
    attr_reader :pipeline, :event

    class PipelineConfigError
    end

    def self.trigger_when?(event)
      true
    end

    def self.stages
      @stages ||= []
    end

    def self.stage_options
      @stage_options ||= {}
    end

    def self.ensure_stages
      @ensure ||= []
    end

    def self.stage(name, opts={})
      stages << name.to_sym
      stage_options[name.to_sym] = opts
    end

    def self.ensure_stage(name)
      ensure_stages << name.to_sym
    end

    def initialize(pipeline, event)
      @pipeline = pipeline
      @event = event
      @job_creation_idx = 0
    end

    def create_job(key: nil, project: nil, scm: nil, spec: nil)
      project = self.project unless project

      scm = {} if scm.nil?
      if project
        scm[:owner] = project.repo_owner
        scm[:name] = project.repo_name
        scm[:provider] = project.repo_provider
      end

      @job_creation_idx += 1
      key = "#{pipeline.definition.underscore}.#{pipeline.id}.#{stage}-#{@job_creation_idx}" unless key

      Job.create!(
          pipeline: pipeline,
          pipeline_stage: stage,
          status: 'QUEUED',
          spec: spec.merge(repo: scm),
          commit: scm[:commit],
          branch: scm[:branch],
          key: key,
      )
    end

    def create_default_job(spec)
      scm = {}
      if event.data[:commit]
        scm[:commit] = event.data[:commit]
        scm[:branch] = event.data[:branch]
        scm[:pull_request] = event.data[:pull_request]
      else
        latest = project.owner.client.latest_commit(project.repo_name)
        scm[:commit] = latest[:sha]
        scm[:branch] = latest[:branch]
      end

      create_job(
          project: project,
          scm: scm,
          spec: spec,
      )
    end

    def project=(project)
      pipeline.update!(project_id: project.id)
      @project = project
    end

    def project
      @project ||= pipeline.project
    end

    def stage
      pipeline.stage
    end

    def next
      pipeline.run
    end

    def variables
      @variables ||= OpenStruct.new(pipeline.variables)
    end

    def save
      pipeline.update!(variables: variables.to_h)
    end

    def load_file(name)
      project.owner.client.file(project.repo_name, name)
    end

    def load_yml_file(name)
      file = load_file(name)
      HashWithIndifferentAccess.new(YAML.load(file)) if file
    end

    def self.as_json
      {
          stages: stages.map { |stage| stage_options.merge(stage: stage) },
          name: name,
      }
    end

  end
end
