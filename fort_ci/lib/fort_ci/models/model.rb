require "active_record"

module FortCI
  class Model < ActiveRecord::Base
    self.abstract_class = true
  end
end
