require "faraday"

module SimpleCi
  class GithubClient

    def initialize(username, token)
      @token = token
      @username = username
    end

    def teams
      req(:get, 'user/orgs').map do |org|
        {id: org['id'], name: org['login']}
      end
    end

    def repo(repo)
      res = req(:get, "/repos/#{@username}/#{repo}")

      if res['source']
        {
            id: res['source']['id'],
            name: res['source']['name'],
            owner: res['source']['owner']['login'],
            owner_id: res['source']['owner']['id'],
        }
      else
        {
            id: res['id'],
            name: res['name'],
            owner: res['owner']['login'],
            owner_id: res['owner']['id'],
        }
      end
    end

    def latest_commit(repo)
      res = req(:get, "/repos/#{@username}/#{repo}/git/refs")
      return nil if res.length == 0

      res.each do |ref|
        if ref['ref'].split('/')[1] == 'heads'
          return {
              sha: ref['object']['sha'],
              branch: ref['ref'].split('refs/heads/')[-1],
          }
        end
      end

      nil
    end

    def branches(repo)
      req_cached(:get, "/repos/#{@username}/#{repo}/branches").map do |branch|
        {name: branch['name'], commit: branch['commit']['sha']}
      end
    end

    def file(repo, path)
      res = req(:get, "/repos/#{@username}/#{repo}/contents/#{path}")
      Base64.decode64(res['content']) if res['content']
    end

    def register_webhook(repo)
      post_json("/repos/#{@username}/#{repo}/hooks", {
          name: 'web',
          active: true,
          events: %w(push pull_request),
          config: {
              url: "#{Config.api_root_url}/hooks/github",
              content_type: 'json',
              _owner: 'simpleci',
          }
      })
    end

    def remove_webhooks(repo)
      req(:get, "/repos/#{@username}/#{repo}/hooks").each do |hook|
        if hook['config']['_owner'] == 'simpleci'
          req(:delete, "/repos/#{@username}/#{repo}/hooks/#{hook['id']}")
        end
      end
    end

    def req(method, url, params={})
      puts "#{method}  https://api.github.com/#{url}"
      res = conn.send(method, url, params)
      JSON.parse(res.body) if res.body && res.body.length > 0
    end

    def post_json(url, payload)
      res = conn.post do |req|
        req.url url
        req.headers['Content-Type'] = 'application/json'
        req.body = JSON.generate(payload)
      end
      JSON.parse(res.body)
    end

    def req_cached(method, url, params={})
      Rails.cache.fetch("github-api:#{method}.#{url}", expires_in: 1.day) { req(method, url, params) }
    end

    def conn
      @github ||= Faraday.new(url: 'https://api.github.com/') do |faraday|
        faraday.request  :url_encoded             # form-encode POST params
        faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
        faraday.headers['Authorization'] = "token #{@token}"
      end
    end

  end
end
