require "fort_ci/models/model"

module FortCI
  class Project < Model
    belongs_to :team, optional: true
    belongs_to :user, optional: true
    has_many :pipelines
    has_many :jobs, through: :pipelines

    after_destroy { remove_hooks }
    after_create { register_hooks }

    serialize :enabled_pipelines, JSON

    def self.add_project(user, name)
      repo = user.client.repo(name)

      found = Project.find_by(repo_id: repo[:id])
      return found if found

      project = {
          name: repo[:name],
          repo_provider: user.provider,
          repo_owner: repo[:owner],
          repo_name: repo[:name],
          repo_id: repo[:id],
      }

      team = user.teams.find_by(provider_id: repo[:owner_id])
      if team
        project[:team] = team
      else
        project[:user] = user
      end

      create!(project)
    end

    def status
      jobs.where(branch: 'master').last.try(:status)
    end

    def branches
      jobs.group(:branch).limit(20).pluck(:branch).map do |branch|
        jobs.where(branch: branch).first
      end
    end

    def register_hooks
      owner.client.register_webhook(repo_name)
    end

    def remove_hooks
      owner.client.remove_webhooks(repo_name)
    end

    def owner
      user || team
    end

  end
end
