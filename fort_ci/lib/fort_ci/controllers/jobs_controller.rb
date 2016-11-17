require "sinatra/extension"

module SimpleCi
  module JobsController
    extend Sinatra::Extension

    before("/jobs/?*")   { protected! }
    before("/worker/*") { authorize_worker! }

    get "/worker/jobs/dequeue/?" do
      job = Job.pop(current_worker)
      if job
        json job, show_all: true, serializer: JobRunnerSerializer, root: :job
      else
        json({job: nil})
      end
    end

    post "/worker/jobs/:id/reject/?" do
      Job.reject(current_worker, params[:id])
      halt 200
    end

    post "/worker/jobs/:id/status/?" do
      Job.update_status(current_worker, params[:id], params[:status])
      halt 200
    end

    get "/jobs/?" do
      json current_entity.jobs, root: 'jobs'
    end

    get "/jobs/:id/?" do
      json current_entity.jobs.find(params[:id]), show_all: true, root: 'job'
    end

    get "/jobs/:id/output/?" do
      json current_entity.jobs.find(params[:id]).output, root: :output
    end

    post "/jobs/:id/cancel/?" do
      json current_entity.jobs.find(params[:id]).cancel, root: :job
    end

  end
end
