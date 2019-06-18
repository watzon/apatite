require "./apatite/core_ext/array"

require "./apatite/linear_algebra"

# Apatite is a fundimental package for scientific computing in Crystal. If that
# sounds like a modified version of the first line from the NumPy homepage,
# that's because it is. Apatite has (ok, will have) all of the goodness
# of NumPy sitting atop the blazing speed and beautiful syntax
# of Crystal.
module Apatite
  extend self

  include Apatite::LinearAlgebra

  class_property precision = 1e-6
  class_property approx_precision = 1e-5

  ## ## ## ## ## ## ## ## ## ## ## ## ##
  # # Vector Creation
  ## ## ## ## ## ## ## ## ## ## ## ## ##

  # Cartesian unit vector I
  #
  # `Vector{1.0, 0.0, 0.0}`
  I = Vector::I

  # Cartesian unit vector J
  #
  # `Vector{0.0, 1.0, 0.0}`
  J = Vector::J

  # Cartesian unit vector K
  #
  # `Vector{0.0, 0.0, 1.0}`
  K = Vector::K

  # Returns a new empty `Vector`
  def empty
    Vector.new
  end

  # Returns a new vector filled with `n` ones.
  def ones(n)
    Vector.ones(n)
  end

  # Returns a new vector filled with `n` zeros.
  def zeros(n)
    Vector.zeros(n)
  end

  # Returns a new vector of size `n` filled with `i`
  def full(n, i)
    Vector.new(n, i)
  end

  # Creates a new vector of size `n`, and invokes the block once
  # for each index of `self`, assigning the block's value in that index.
  def vector(n, &block)
    Vector.new(n) { |i| yield i }
  end

  # Creates a new vector from the given `input`. Input can be any
  # `Indexable` type.
  def as_vector(input : Indexable)
    Vector.create(input)
  end

  # Creates a standard basis-n vector of the given `size` and `index`.
  def basis(size, index)
    Vector.basis(size, index)
  end

  # Creates a new vector of size `n` filled with random numbers. A `range`
  # can optionally be passed in if you want to limit the random numbers
  # to a given range.
  def random(n, range = nil)
    Vector.random(n, range)
  end

  ## ## ## ## ## ## ## ## ## ## ## ##
  # # Matrix Creation
  ## ## ## ## ## ## ## ## ## ## ## ##

  # Creates a new empty matrix with the given `row_count` and
  # `column_count`. At lease one of `row_count` or
  # `column_count` must be zero.
  def empty_matrix(row_count = 0, column_count = 0)
    Matrix.empty(row_count, column_count)
  end

  # Creates a matrix where the diagonal elements are composed of `values`.
  def diagonal(values)
    Matrix.diagonal(values)
  end

  # Creates a new diagonal matrix of size `n` with ones in the diagonal
  # and zeros elsewhere.
  def eye(n)
    Matrix.eye(n)
  end

  # Creates a `n x n` identity matrix.
  def identity(n)
    Matrix.identity(n)
  end

  # Creates a single-row matrix where the values of that row are as given in `row`.
  def row_vector(row)
    Matrix.row_vector(row)
  end

  # Creates an `n` by `n` diagonal matrix where each diagonal element is value.
  def scalar(n, value)
    Matrix.scalar(n, value)
  end

  ## ## ## ## ## ## ## ## ## ## ## ##
  # # Vector Manipulation
  ## ## ## ## ## ## ## ## ## ## ## ##

  # Get the scalar (dot) product of two vectors.
  #
  # [https://en.wikipedia.org/wiki/Scalar_product](https://en.wikipedia.org/wiki/Scalar_product
  def dot(x, y)
    unless x.size == y.size
      raise "Cannot compute the dot product of vectors with different dimensionality"
    end

    (0...x.size).reduce(0) do |acc, i|
      acc + x[i] * y[i]
    end
  end

  # Compute the cosine similarity of two vectors.
  def similarity(x, y)
    dot(x, y) / (
      Math.sqrt(dot(x, x)) *
      Math.sqrt(dot(y, y))
    )
  end

  # Compute the cosine distance between two vectors.
  def cosine(x, y)
    1.0 - similarity(x, y)
  end

  # Returns the angle between this vector and another in radians.
  # If the vectors are mirrored across their axes this will return `nil`.
  def angle_from(a, b)
    unless a.size == b.size
      raise "Cannot compute the angle between vectors with different dimensionality"
    end

    dot = 0_f64
    mod1 = 0_f64
    mod2 = 0_f64

    a.zip(b).each do |x, v|
      dot += x * v
      mod1 += x * x
      mod2 += v * v
    end

    mod1 = Math.sqrt(mod1)
    mod2 = Math.sqrt(mod2)

    if mod2 * mod2 == 0
      return 0.0
    end

    theta = (dot / (mod1 * mod2)).clamp(-1, 1)
    Math.acos(theta)
  end

  # Returns whether the vectors are parallel to each other.
  def parallel_to?(a, b)
    angle = angle_from(a, b)
    angle <= precision
  end

  # Returns whether the vectors are antiparallel to each other.
  def antiparallel_to?(a, b)
    angle = angle_from(a, b)
    (angle - Math::PI).abs <= precision
  end

  # Returns whether the vectors are perpendicular to each other.
  def perpendicular_to?(a, b)
    (dot(a, b)).abs <= precision
  end
end
