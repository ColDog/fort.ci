require "active_record"

require "active_support/all"

require "fort_ci/config"

# tells AR what db file to use
ActiveRecord::Base.establish_connection(Config.database)

require "fort_ci/jobs"
require "fort_ci/event"
require "fort_ci/pipeline_definition"
require "fort_ci/pipelines/basic_pipeline"
require "fort_ci/clients/github_client"

require "fort_ci/models/model"
require "fort_ci/models/job"
require "fort_ci/models/pipeline"
require "fort_ci/models/project"
require "fort_ci/models/team"
require "fort_ci/models/user"
require "fort_ci/models/user_team"

require "fort_ci/jobs/event_handler_job"
require "fort_ci/jobs/pipeline_stage_job"
