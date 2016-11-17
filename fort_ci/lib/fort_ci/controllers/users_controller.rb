require "sinatra/extension"

module FortCI
  module UsersController
    extend Sinatra::Extension

    before("/users/?*") { protected! }
    before("/teams/?*") { protected! }

    get "/users/current_user/?" do
      json current_user
    end

    get "/users/?" do
      json current_entity.users
    end

    get "/teams/?" do
      json current_user.teams
    end

  end
end
