# Apatite

Apatite is meant to be a collecion of mathmatical and scientific computing algorithms for the Crystal programming language. I don't expect it to ever reach the level of completeness as numpy, but hopefully it can save some people the trouble of implementing these methods on their own.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     apatite:
       github: watzon/apatite
   ```

2. Run `shards install`

## Usage

```crystal
require "apatite"
```

Check out the [documentation](https://watzon.github.io/apatite/) for usage examples.

## Roadmap

- [ ] Linear Algebra
	- [x] Vector
	- [ ] Matrix (_in progress_)
	- [ ] NDArray
	- [ ] Line
	- [ ] Plane
	- [ ] Polygon
	- [ ] LinkedList
	


## Contributing

1. Fork it (<https://github.com/watzon/apatite/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Chris Watson](https://github.com/watzon) - creator and maintainer