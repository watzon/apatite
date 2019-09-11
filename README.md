# Apatite

[<img src="https://github.com/watzon/apatite/workflows/Specs/badge.svg">](https://github.com/watzon/apatite/actions)

Apatite is a collection of mathematical and scientific algorithms. Currently it implements the API from Ruby's `Matrix` class for both `Matrix` and `Vector`. This API will be added to as needs arise. The goal is for this project to eventually contain everything you could get from SciPy, but in pure Crystal.

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
	- [x] Matrix
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
