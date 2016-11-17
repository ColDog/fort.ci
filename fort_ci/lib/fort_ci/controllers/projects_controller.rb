require "sinatra/extension"

module SimpleCi
  module ProjectsController
    extend Sinatra::Extension

    before("/projects/?*") { protected! }

    get "/projects/?" do
      json current_user.projects
    end

    post "/projects/?" do
      json Project.add_project(current_user, params[:name])
    end

    get "/projects/:id/?" do
      json current_user.projects.find(params[:id])
    end

    put "/projects/:id/?" do
      project = current_user.projects.find(params[:id])
      project.update!(params[:project])
      json project
    end

    delete "/projects/:id/?" do
      json current_user.projects.find(params[:id]).destroy!
    end

    get "/projects/:id/jobs/?" do
      json current_user.projects.find(params[:id]).jobs, root: :jobs
    end

    get "/projects/:id/branches/?" do
      json current_user.projects.find(params[:id]).branches, root: :jobs
    end

  end
end
