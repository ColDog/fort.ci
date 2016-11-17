require "fort_ci/models/model"
# Job Spec:
# {
#   sections: [
#     { name: "name", on_success: [], on_failure: [], commands: [], fail_on_err: true }
#   ],
#   services: [
#     { name: "", docker: { ... } }
#   ],
#   repo: {
#     name: "repo",
#     owner: "repo-owner",
#     commit: "abcdefg",
#     branch: "feature/x",
#     provider: "github.com",
#   }
# }
#
module SimpleCi
  class Job < Model
    STATUSES = %w(QUEUED PROCESSING FAILED COMPLETED CANCELLED).freeze

    class WorkerError < Exception
    end

    belongs_to :pipeline
    has_one :project, through: :pipeline

    before_validation { self.status = 'QUEUED' unless status.present? }
    after_save { pipeline.run if status_changed? }
    serialize :spec, JSON
    validate { errors.add(:status, "is not valid") unless STATUSES.include?(status) }

    def self.pop(worker)
      Job.where(status: 'QUEUED', worker: nil).limit(1).update(worker: worker, status: 'PROCESSING').first
    end

    def self.reject(worker, id)
      Job.where(key: id, worker: worker).update(worker: nil, status: 'QUEUED')
    end

    def self.update_status(worker, id, status)
      Job.where(key: id, worker: worker).update(status: status.to_s.upcase)
    end

    def spec
      @spec ||= super.try(:symbolize_keys)
    end

    def cancel
      if worker
        res = conn.delete("/jobs/#{key}")
        if res.status < 200 || res.status > 300
          raise WorkerError.new(res.body)
        end
      end
    ensure
      update(status: 'CANCELLED')
    end

    def output
      res = conn.get("/jobs/#{key}")
      if res.status < 200 || res.status > 300
        raise WorkerError.new(res.body)
      end

      JSON.parse(res.body)
    end

    def conn
      @conn = Faraday.new(url: "http://#{worker}") do |faraday|
        faraday.request  :url_encoded             # form-encode POST params
        faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
      end
    end

  end
end
