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
  I = Vector::I

  # Cartesian unit vector J
  J = Vector::J

  # Cartesian unit vector K
  K = Vector::K

  # Returns a new empty `Vector`
  def empty
    Vector.new
  end

  # Returns a new vector filled with `n` ones.
  def ones(n)
    Vector.new(n, 1)
  end

  # Returns a new vector filled with `n` zeros.
  def zeros(n)
    Vector.new(n, 0)
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

  # Returns a standard basis-n vector of the given `size` and `index`.
  def basis(size, index)
    Vector.basis(size, index)
  end

  ## ## ## ## ## ## ## ## ## ## ## ##
  # # Matrix Creation
  ## ## ## ## ## ## ## ## ## ## ## ##

end
