require "sinatra/extension"

module FortCI
  module SessionsController
    extend Sinatra::Extension

    get "/auth/:provider/callback/?" do
      user = User.from_omniauth(request.env['omniauth.auth'])
      session[:user_id] = user.id
      redirect Config.ui_root_url
    end

    delete "/auth/?" do
      session[:user_id] = nil
    end

  end
end
