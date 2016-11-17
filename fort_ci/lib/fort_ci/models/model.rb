require "active_record"

module SimpleCi
  class Model < ActiveRecord::Base
    self.abstract_class = true
  end
end
