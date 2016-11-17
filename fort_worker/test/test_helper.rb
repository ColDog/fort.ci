$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'fort_ci/worker'

$VERBOSE=nil

require 'minitest/autorun'

FortCI::Worker.db = { adapter: 'mysql2', database: 'worker-test', user: 'root' }
FortCI::Worker.queue = FortCI::Worker::Queue.new
FortCI::Worker.logger = Logger.new(STDOUT)
