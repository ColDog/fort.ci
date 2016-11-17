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

Worker.db = copy || Config.database
Worker.queue = Worker::Queue.new
Worker.queue.log_backtrace = true
Worker.logger = Log
