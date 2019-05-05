# Apatite

Apatite is a fundimental package for scientific computing in Crystal. If that sounds like a modified version of the first line from the NumPy homepage, that's because it is. Apatite has (ok, will have) all of the goodness of NumPy sitting atop the blazing speed and beautiful syntax of Crystal.

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

TODO: Write usage instructions here, but first write the library...

## Roadmap

[ ] Apetite
	[ ] Array Objects
		[ ] NArray (see [numpy.ndarray](https://docs.scipy.org/doc/numpy/reference/arrays.ndarray.html))
		[ ] DType  (see [numpy.dtype](https://docs.scipy.org/doc/numpy/reference/arrays.dtypes.html))
		[ ] Scalars
		[ ] Indexing
	[ ] Routines
		[ ] Binary Operations
		[ ] String Operations
		[ ] FFT    (see [numpy.fft](https://docs.scipy.org/doc/numpy/reference/routines.fft.html))
		[ ] Financial Functions
		[ ] LinAlg (see [numpy.linalg](https://docs.scipy.org/doc/numpy/reference/routines.linalg.html))
		[ ] Logic Functions
		[ ] Mathematical Functions
		[ ] Matlib (see [numpy.matlib](https://docs.scipy.org/doc/numpy/reference/routines.matlib.html))
		[ ] Padding Arrays
		[ ] Polynomials
		[ ] Random (see [numpy.random](https://docs.scipy.org/doc/numpy/reference/routines.random.html))
		[ ] Sorting, Searching, and Counting
		[ ] Statistics

## Contributing

1. Fork it (<https://github.com/watzon/apatite/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Chris Watson](https://github.com/watzon) - creator and maintainer