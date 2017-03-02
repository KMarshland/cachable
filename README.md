# Cachable
Caching is often a bother. This gem allows you to simply wrap your code in a block and have it be cached with redis.

## Usage
In your model:

```ruby
include Cachable

def your_method
  unless_cached do 
    # ... output of this will be cached    
  end
end
```

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'cachable'
```


## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
