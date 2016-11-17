require "fort_ci/models/model"

module FortCI
  class UserTeam < Model
    belongs_to :user
    belongs_to :team
  end
end
