# Cachable
Caching is often a bother. This gem allows you to simply wrap your code in a block and have it be cached with redis.

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'cachable'
```

## Usage
At its hearty, this gem is the `unless_cached` method. In your model:

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


## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
