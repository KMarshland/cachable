
module Cachable
  class Configuration
    attr_accessible :redis_connection, :redis_instance, :redis_url

    def redis
      return @redis_connection.call if @redis_connection.present?
      return @redis_instance if @redis_connection.present?


      @redis_url = ENV['REDIS_URL'] || ENV['HEROKU_REDIS_URL']
      raise 'No redis url provided' if @redis_url.blank?

      uri = URI.parse(@redis_url)
      @redis_instance = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
    end
  end

  def self.configure
    @config ||= Configuration.new

    yield @config
  end

  def self.redis
    @config.redis
  end

end