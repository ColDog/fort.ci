require "yaml"
require "logger"

class AppConfig
  attr_accessor :ui_root_url, :api_root_url, :env, :secret

  def initialize
    @ui_root_url = ENV['UI_ROOT'] || 'http://localhost:3000'
    @api_root_url = ENV['API_ROOT'] || 'http://localhost:3000/api'
    @database = HashWithIndifferentAccess.new(YAML.load(File.new('./database.yml')))
    @env = ENV['RAILS_ENV'] || ENV['RACK_ENV'] || ENV['ENV'] || 'development'
    @secret = ENV['SECRET_KEY_BASE'] || 'secret'
  end

  def database
    @database[@env]
  end

end

# global constants
Config = AppConfig.new
Log = Logger.new(STDOUT)
