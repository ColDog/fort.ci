require "fort_ci/env"
require "worker"

copy = nil
if Config.database[:adapter] == 'sqlite3'
  copy = {}
  Config.database.each do |k, v|
    copy[k] = v
  end
  copy['adapter'] = 'sqlite'
end

FortCI::Worker.db = copy || Config.database
FortCI::Worker.queue = FortCI::Worker::Queue.new
FortCI::Worker.queue.log_backtrace = true
FortCI::Worker.logger = Log
