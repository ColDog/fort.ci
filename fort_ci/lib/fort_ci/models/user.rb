require "fort_ci/models/model"

module SimpleCi
  class User < Model
    has_many :user_teams
    has_many :teams, through: :user_teams
    has_many :users, through: :teams
    has_many :projects
    has_many :pipelines, through: :projects
    has_many :jobs, through: :pipelines

    def self.from_omniauth(auth)
      new_user = false
      user = User.find_by(provider: auth.provider, provider_id: auth.uid)
      unless user.present?
        user = User.create!(provider: auth.provider, provider_id: auth.uid)
        new_user = true
      end

      user.username = auth.info.nickname
      user.email = auth.info.email
      user.name = auth.info.name
      user.token = auth.credentials.token
      user.refresh_token = auth.credentials.refresh_token
      user.save!

      user.sync if new_user

      user
    end

    def sync
      client.teams.each do |team|
        teams.create!(provider: provider, provider_id: team[:id], name: team[:name])
      end
    end

    def client
      if provider == 'github'
        GithubClient.new(username, token)
      else
        nil
      end
    end

    def to_s
      "#<User(#{id}) username=#{username} provider=#{provider}>"
    end

  end
end
