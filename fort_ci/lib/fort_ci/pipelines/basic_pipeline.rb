require "fort_ci/pipeline_definition"

class BasicPipeline < FortCI::PipelineDefinition
  stage :first

  def first
    create_default_job(basic_job_from_file)
  end

  def basic_job_from_file
    ci_file = project.owner.client.file(project.repo_name, 'ci.yml')
    if ci_file
      spec = {}
      build = HashWithIndifferentAccess.new(YAML.load(ci_file))

      # services are copied directly
      spec[:services] = build[:services]

      # turns each key into a section
      spec[:sections] = []

      spec[:sections] << {
          name: 'setup',
          fail_on_err: true,
          commands: build[:setup],
          on_success: build[:on_success],
          on_failure: build[:on_failure],
      }

      spec[:sections] << {
          name: 'test',
          fail_on_err: true,
          commands: build[:test],
          on_success: build[:on_success],
          on_failure: build[:on_failure],
      }

      spec[:sections] << {
          name: 'after',
          fail_on_err: true,
          commands: build[:after],
      }

      spec
    else
      {
          sections: [
              {
                  name: 'test',
                  fail_on_err: true,
                  commands: [
                      'echo "no ci.yml file found"',
                      'exit 1',
                  ],
              }
          ]
      }
    end
  end

end
