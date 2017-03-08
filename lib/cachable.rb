require 'cachable/configuration'

module Cachable

  extend ActiveSupport::Concern

  included do

    after_commit :purge_cache #try to purge the cache after anything changes

    #Generates the basic redis key from id, updated_at, and whatever else we want
    def base_redis_key(opts={})
      added = ''
      added = "_#{self.added_redis_key}" if self.respond_to? :added_redis_key

      on_previous_changes = opts[:after_commit] && self.previous_changes['updated_at']
      updated_at = on_previous_changes ? self.previous_changes['updated_at'].first : self.updated_at

      "#{self.class.to_s.downcase}_#{self.id}_#{updated_at.to_i}#{added}"
    end

    #Clears the given keys from redis
    def delete_from_cache(*keys, **opts)
      base_key = self.base_redis_key opts
      keys.each do |key|
        Cachable::redis.del "#{base_key}_#{key}"
      end
    end

    # Purges the cache for this record, if the client has defined the purge_cache method
    def purge_cache
      return unless self.respond_to? :tracked_cache_keys

      self.delete_from_cache(*self.tracked_cache_keys, after_commit: true)
    end

    # If the is present in the cache, returns that; otherwise generates and caches the result
    # opts[:key]. If present, will be added to the base key to generate the full key. Defaults to the name of the caller.
    # opts[:json]. If true, will serialize and deserialize the result as json
    # opts[:expiration]. Time for which to cache the result. Defaults to 1 day
    # opts[:json_options]. Options that get passed into json serialization and deserialization
    def unless_cached(opts={})
      partial_key = opts[:key].present? ? opts[:key] : caller.first.match(/`[^']*/).to_s[1..-1]
      key = "#{self.base_redis_key}_#{partial_key}"

      self.class.unless_cached_base(key, opts) do
        yield
      end
    end

    # Calls unless cached on all records passed
    # action
    # opts[:slurp]. If true will not pull the records in in batches, which increases memory overhead but preserves order.
    # opts[:force_cache]. If true will add its own cache, regardless of what the underlying function does
    # opts[:cache_batches]. If true will add another layer of caching outside
    # opts[:skip_result]. If true will not generate (useful for prepopulating the cache with lower overhead)
    # opts[clear_previous_batch] If true, and was also true previous times, it will remove the cached batches for the previous batch. This can be very useful when you are frequently adding more records and want to keep the redis memory usage down.
    # Can also pass in all normal unless_cached options
    def self.unless_cached(action, opts={})
      result = []

      iterator = all.find_in_batches
      iterator = all.each_in_order_in_batches if self.respond_to? :each_in_order_in_batches
      iterator = all.each if opts[:slurp]

      partial_key = opts[:key].present? ? opts[:key] : action
      added_key = ''
      added_key = "_#{self.added_redis_key}" if self.respond_to? :added_redis_key

      batch_key_list = []
      record_count = 0

      opts[:skip_cache] = !opts[:force_cache]

      iterator.each do |batch|
        factors = batch.pluck(:id, :updated_at)
        record_count += factors.length if opts[:clear_previous_batch]

        if opts[:cache_batches]
          batch_key = "#{self.to_s.downcase}_#{factors.flatten.join(',')}#{added_key}_#{partial_key}"
          batch_key_list << batch_key if opts[:clear_previous_batch]

          existing_result = Cachable::redis.get batch_key
          if existing_result.present?
            result.concat JSON(existing_result)
            next
          end
        end

        batch_result = factors.map do |id, updated_at|
          key = "#{self.to_s.downcase}_#{id}_#{updated_at.to_i}#{added_key}_#{partial_key}"

          self.unless_cached_base(key, opts) do
            record = self.unscope(:order, :where, :offset).find id

            block_given? ? (yield record) : record.send(action) if record.present?
          end
        end

        result.concat batch_result unless opts[:skip_result]

        if opts[:cache_batches]
          Cachable::redis.set batch_key, JSON(batch_result)
          expiration = opts[:expiration]
          expiration = 15.minutes unless expiration.present?
          Cachable::redis.expire batch_key, expiration unless expiration === false
        end
      end

      if opts[:clear_previous_batch]

        # store the keys for the current batch list
        expiration = opts[:expiration]
        expiration = 15.minutes unless expiration.present?

        gen_key -> n {
          "#{self.to_s.downcase}_keys_#{n}_#{added_key}_#{partial_key}"
        }
        batch_key = gen_key[record_count]

        Cachable::redis.set(batch_key, JSON(batch_key_list))
        Cachable::redis.expire(batch_key, expiration)

        # delete the keys from the previous batch list
        Cachable::redis.del(gen_key[record_count - 1])
        Cachable::redis.del(gen_key[record_count + 1])
      end

      result
    end

    # Core implementation of unless cached.
    # As well as options from above:
    # opts[:skip_cache]. If true, will not populate the cache
    def self.unless_cached_base(key, opts={})
      opts[:json] = true if opts[:json].nil?

      cached = Cachable::redis.get(key)
      if cached.present?
        cached = JSON.parse(cached, opts[:json_options]) if opts[:json]

        return cached
      end

      result = yield

      unless opts[:skip_cache]
        if opts[:json]
          Cachable::redis.set(key, JSON.generate(result, opts[:json_options]))
        else
          Cachable::redis.set(key, result)
        end

        expiration = opts[:expiration]
        expiration = 1.day unless expiration.present?
        Cachable::redis.expire(key, expiration) unless expiration === false
      end

      result

    end

  end

end
