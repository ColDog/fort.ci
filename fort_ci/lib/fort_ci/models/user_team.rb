require "fort_ci/models/model"

module SimpleCi
  class UserTeam < Model
    belongs_to :user
    belongs_to :team
  end
end
