require "sinatra/extension"
require "fort_ci/event"

module FortCI
  module EventsController
    extend Sinatra::Extension

    before("/events/?*") { protected! }

    post "/events/?" do
      # authorizes the event
      current_user.projects.find(params[:project_id])

      event = Event.new(
          project_id: params[:project_id],
          name: params[:name],
      )
      event.execute
      json(event: event)
    end

  end
end
