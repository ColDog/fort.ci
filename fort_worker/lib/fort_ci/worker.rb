require "fort_ci/worker/version"
require "fort_ci/worker/queue"
require "fort_ci/worker/job"
require "logger"

module FortCI
  module Worker
    class << self
      attr_accessor :queue, :logger, :db
    end
  end
end
