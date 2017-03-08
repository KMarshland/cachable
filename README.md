# Cachable
Caching is often a bother. This gem allows you to simply wrap your code in a block and have it be cached with redis.

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'cachable'
```

You must also add redis to your app. On heroku, you can add [Heroku Redis](https://elements.heroku.com/addons/heroku-redis).

## Usage
At its hearty, this gem is the `unless_cached` method. 
Although no options are required, it accepts the following:
 - key. If present, will be added to the base key to generate the full key. Defaults to the name of the caller.
 - json. If true, will serialize and deserialize the result as json
 - expiration Time for which to cache the result. Defaults to 1 day
 - json_options. Options that get passed into json serialization and deserialization
 - skip_cache. If true, will not populate the cache -- this can be used if you populate the cache elsewhere, but still want to check if there's something there. 

### Examples
In your model:

```ruby
include Cachable

def your_method
  unless_cached do 
    # ... output of this will be cached under the key model_name_id_updated_at_your_method 
  end
end
```

Of course, `unless_cached` accepts a variety of options:
```ruby
# opts[:key]. If present, will be added to the base key to generate the full key. Defaults to the name of the caller.
unless_cached(key: 'some_key') do
  # will be stored under the key model_name_id_some_key
end


# opts[:json]. If true, will serialize and deserialize the result as json
unless_cached(json: true) do
  {
    json: 'object'
  }
end

# opts[:expiration]. Time for which to cache the result. Defaults to 1 day
unless_cached(expiration: 30.minutes) do
  # result will expire in half an hour
end


# opts[:json_options]. Options that get passed into json serialization and deserialization
unless_cached(json: true, json_options: {allow_nan: true}) do
  {
    value: Float::NAN
  }
end
```

## Other features

### Deleting from the cache
Sometimes you want to delete something from the cache. 
This can be done using the `delete_from_cache` method, which takes in one or more keys. 
These keys are either the 
```ruby
delete_from_cache(:key1, :key2)
```

A special use case is after the changes have been committed. 
For this, you can use the special `purge_cache` callback. 
You must define the `tracked_cache_keys` method for this to work properly. 
The following example will clear the cache for `cached_a` and `cached_b`, but not `cached_c`.
```ruby
# in your model
after_commit :purge_cache

def tracked_cache_keys
  [:cached_a, :cached_b]
end

def cached_a
  unless_cached do 
    # ...
  end
end

def cached_b
  unless_cached do 
    # ...
  end
end

def cached_c
  unless_cached do 
    # ...
  end
end
```

If you want to use the `delete_from_cache` method directly in an `after_commit` callback, you must specify that in the options.
```ruby
delete_from_cache(:key1, :key2, after_commit: true)
```

### Adding an additional redis key
Sometimes your cache depends on more than just the model. 
For example, imagine you have a model book that `belongs_to` an author. 
When the author is updated, you want the cache to become invalidated.
In your book model, you might have something like this:
```ruby
def added_redis_key
  self.author.updated_at.to_i
end

def self.added_redis_key
  first = all.first
  return '' if first.blank?

  first.author.updated_at.to_i
end

```

### Using the cache outside of a specific instance
Sometimes you need to cache something in a static (class) method. It accepts the following options:
- json. If true, will serialize and deserialize the result as json
- expiration Time for which to cache the result. Defaults to 1 day
- json_options. Options that get passed into json serialization and deserialization
- skip_cache. If true, will not populate the cache -- this can be used if you populate the cache elsewhere, but still want to check if there's something there. 
```ruby
self.class.unless_cached_base("#{self.class.to_s.downcase}_key", json: true, expiration: 1.day) do
 # this output will be cached under the key your_model_name_key
end
```

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
