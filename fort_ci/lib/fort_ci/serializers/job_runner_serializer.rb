require "fort_ci/serializers/serializer"

# ID       string     `json:"id"`
# Name     string     `json:"name"`
# Repo     *Repo      `json:"repo"`
# Builds   []*Build   `json:"builds"`
# Services []*Service `json:"services"`
# Sections []*Section `json:"sections"`
# Env      []string   `json:"env"`
module SimpleCi
  class JobRunnerSerializer < BaseSerializer
    attributes :id, :repo, :builds, :services, :sections, :env

    def id
      object.key
    end

    def repo
      object.spec.try(:[], :repo)
    end

    def builds
      object.spec.try(:[], :builds)
    end

    def services
      object.spec.try(:[], :services)
    end

    def sections
      object.spec.try(:[], :sections)
    end

    def env
      object.spec.try(:[], :env)
    end

  end
end
