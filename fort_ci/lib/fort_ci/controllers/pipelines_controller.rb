require "sinatra/extension"

module FortCI
  module PipelinesController
    extend Sinatra::Extension

    before("/pipelines/?*") { protected! }

    get "/pipelines/?" do
      json current_entity.pipelines
    end

    get "/pipelines/:id/?" do
      json current_entity.pipelines.find(params[:id]), show_all: true
    end

  end
end
