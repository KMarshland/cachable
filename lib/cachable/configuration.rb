
module Cachable
  class Configuration
    attr_accessor :redis_connection, :redis_instance, :redis_url

    def redis
      return @redis_connection.call if @redis_connection.present?
      return @redis_instance if @redis_instance.present?


      @redis_url = ENV['REDIS_URL'] || ENV['HEROKU_REDIS_URL']
      raise 'No redis url provided' if @redis_url.blank?

      uri = URI.parse(@redis_url)
      @redis_instance = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
    end
  end

  def self.configuration
    @config ||= Configuration.new
  end

  def self.configure
    yield self.configuration
  end

  def self.redis
    self.configuration.redis
  end

end