require "sinatra/base"
require "fort_ci/env"
require "fort_ci/serializers"

require "fort_ci/controllers/jobs_controller"
require "fort_ci/controllers/sessions_controller"
require "fort_ci/controllers/projects_controller"
require "fort_ci/controllers/events_controller"
require "fort_ci/controllers/hooks_controller"
require "fort_ci/controllers/pipelines_controller"
require "fort_ci/controllers/users_controller"

require "fort_ci/serializers/job_serializer"
require "fort_ci/serializers/job_runner_serializer"
require "fort_ci/serializers/pipeline_serializer"
require "fort_ci/serializers/project_serializer"
require "fort_ci/serializers/team_serializer"
require "fort_ci/serializers/user_serializer"

require "omniauth"
require "omniauth-github"
require "omniauth-bitbucket"

require "jwt"

module SimpleCi
  class App < Sinatra::Base
    disable :show_exceptions
    helpers Sinatra::JSON

    use Rack::Session::Cookie, secret: ENV['SECRET_KEY_BASE'] || 'secret'
    use OmniAuth::Builder do
      provider :github,     ENV['GITHUB_KEY'],    ENV['GITHUB_SECRET'],     scope: %W{ read:org repo user public_repo }
      provider :bitbucket,  ENV['BITBUCKET_KEY'], ENV['BITBUCKET_SECRET'],  scope: %W{ repository issue pullrequest account team webhook }, prompt: 'consent'
    end

    before do
      if request.body.size > 0 && request.content_type == 'application/json'
        request.body.rewind
        self.params = ActiveSupport::JSON.decode(request.body.read)
      end
      self.params = HashWithIndifferentAccess.new(params)
      Log.info("#{request.request_method} #{request.path} params=#{params} auth=#{auth_token} session=#{session[:user_id]} user=#{current_user} entity=#{current_entity}")
    end

    helpers do

      def current_user
        @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
        @current_user ||= User.find_by(id: auth_token[:user_id]) if auth_token[:user_id]

        @current_user
      end

      def current_entity
        @current_entity ||= begin
          if params[:team_id]
            current_user.teams.find(params[:team_id])
          elsif params[:user_id]
            current_user.users.find(params[:user_id])
          else
            current_user
          end
        end
      end

      def current_worker
        auth_token[:worker]
      end

      def protected!
        unless current_user.present?
          json({error: 'Unauthorized', status: 401}, status: 401)
        end
      end

      def authorize_worker!
        unless current_worker.present?
          json({error: 'Unauthorized', status: 401}, status: 401)
        end
      end

      def auth_token
        @auth_token = begin
          token = env['HTTP_AUTHORIZATION'] ? env['HTTP_AUTHORIZATION'].split(' ')[1] : nil
          if token
            payload = JWT.decode(token, Config.secret, true, algorithm: 'HS256').try(:[], 0)
            HashWithIndifferentAccess.new(payload) if payload
          else
            {}
          end
        rescue JWT::VerificationError
          {}
        end
      end

    end

    register JobsController
    register SessionsController
    register ProjectsController
    register EventsController
    register HooksController
    register PipelinesController
    register UsersController

    get "/" do
      json(
          name: 'SimpleCI',
          version: VERSION,
      )
    end

    error(ActiveRecord::RecordNotFound) do
      json({status: 404, message: 'Failed to find the requested resource.'}, status: 404)
    end

    error do |err|
      json({status: 500, message: err.message}, status: 500)
    end

  end
end
