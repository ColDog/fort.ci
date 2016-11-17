require "fort_ci/models/model"

module FortCI
  class Team < Model
    has_many :user_teams
    has_many :users, through: :user_teams
    has_many :projects
    has_many :pipelines, through: :projects

    def client
      users.first.client
    end

    def to_s
      "#<Team(#{id}) name=#{name} provider=#{provider}>"
    end

  end
end
