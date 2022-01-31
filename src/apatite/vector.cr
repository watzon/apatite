require "complex"
require "big"
require "json"

module Apatite
  # Represents a mathematical vector, and also constitutes a row or column
  # of a `Matrix`
  class Vector(T)
    include Indexable(T)
    include Enumerable(T)
    include Comparable(Vector)

    protected getter elements : Array(T)

    delegate :each, :size, to: @elements

    private def initialize(array : Indexable(T))
      {% raise "Vectors must be one type only" if T.union? %}
      @elements = array.to_a
    end

    # Creates a new vector from a list of elements.
    def self.[](*array)
      new(array)
    end

    # Creates a vector from an Array. The optional second argument specifies
    # whether the array itself or a copy is used internally.
    def self.elements(array, copy = true)
      array = array.clone if copy
      new(array)
    end

    # Returns a standard basis `n`-vector.
    def self.basis(size, index)
      raise ArgumentError.new("invalid size (#{size} for 1..)") if size < 1
      raise ArgumentError.new("invalid index (#{index} for 0...#{size})") unless 0 <= index && index < size
      array = Array.new(size, 0)
      array[index] = 1
      new(array)
    end

    # Returns `true` if all of vectors are linearly independent.
    #
    # ```
    # Vector.independent?(Vector[1, 0], Vector[0, 1])
    # # => true
    #
    # Vector.independent?(Vector[1, 2], Vector[2, 4])
    # # => false
    # ```
    def self.independent?(*vs)
      vs.each do |v|
        raise "expected Vector, but got #{v.class}" unless v.is_a?(Vector)
        raise ErrDimensionMismatch.new unless v.size == vs.first.size
      end
      return false if vs.size > vs.first.size
      Matrix.rows(vs.to_a).rank == vs.size
    end

    # Return a zero vector.
    def self.zero(size)
      raise ArgumentError.new("invalid size (#{size} for 0..)") if size < 0
      array = Array.new(size, T.new(0))
      new(array)
    end

    # Alien mothership
    def <=>(other : Vector | Indexable)
      case other
      when Vector
        elements <=> other.elements
      when Indexable
        elements <=> other
      end
    end

    # Multiplies the vector by x, where x is a number.
    def *(x : Number)
      els = @elements.map { |e| (e * x).as(T) }
      self.class.elements(els, false)
    end

    # Multiplies the vector by x, where x is a matrix.
    def *(x : Matrix)
      Matrix.column_vector(self) * x
    end

    # Multiplies the vector by x, where x is another vector.
    def *(x : Vector)
      els = self.elements.zip(x.elements).map { |(x, y)| x * y }
      self.class.elements(els, false)
    end

    # Vector addition.
    def +(x : Number)
      els = @elements.map { |e| (e + x).as(T) }
      self.class.elements(els, false)
    end

    # Vector addition.
    def +(x : Matrix)
      Matrix.column_vector(self) + x
    end

    # Vector addition.
    def +(x : Vector)
      els = self.elements.zip(x.elements).map { |(x, y)| x + y }
      self.class.elements(els, false)
    end

    # Vector subtraction.
    def -(x : Number)
      els = @elements.map { |e| (e - x).as(T) }
      self.class.elements(els, false)
    end

    # Vector subtraction.
    def -(x : Matrix)
      Matrix.column_vector(self) - x
    end

    # Vector subtraction.
    def -(x : Vector)
      els = self.elements.zip(x.elements).map { |(x, y)| x - y }
      self.class.elements(els, false)
    end

    # Vector division.
    def /(x : Number)
      els = @elements.map { |e| (e / x).as(T) }
      self.class.elements(els, false)
    end

    # Vector division.
    def /(x : Matrix)
      Matrix.column_vector(self) / x
    end

    # Vector division.
    def /(x : Vector)
      els = self.elements.zip(x.elements).map { |(x, y)| x / y }
      self.class.elements(els, false)
    end

    # Equality operator
    def ==(other)
      if other.is_a?(Vector)
        @elements == other.elements
      else
        @elements == other
      end
    end

    # Take me to your leader
    def <=>(other)
      if other.is_a?(Vector)
        @elements <=> other.elements
      else
        @elements <=> other
      end
    end

    # Returns an angle with another vector. Result is within the [0…Math::PI].
    def angle_with(v)
      raise ErrDimensionMismatch.new if size != v.size
      prod = magnitude * v.magnitude
      raise ZeroVectorError.new("Can't get angle of zero vector") if prod == 0

      Math.acos(inner_product(v) / prod)
    end

    # Returns a copy of the vector.
    def clone
      self.class.elements(@elements)
    end

    # Maps over a vector, passing each element to the block
    def map(&block : T -> _)
      els = @elements.map(&block)
      self.class.elements(els, false)
    end

    # Maps over the current vector and `v` in conjunction, passing each
    # element in each to the block and returning a new vector
    def map(v, &block : T, T -> _)
      raise ErrDimensionMismatch.new if size != v.size
      arr = Array.new(size) do |i|
        yield @elements[i], v[i]
      end
      self.class.elements(arr, false)
    end

    # Creates a single-row matrix from this vector.
    def covector
      Matrix.row_vector(self)
    end

    # Returns the cross product of this vector with the others.
    def cross_product(*vs)
      raise ErrOperationNotDefined.new("cross product is not defined on vectors of dimension #{size}") unless size >= 2
      raise ArgumentError.new("wrong number of arguments (#{vs.size} for #{size - 2})") unless vs.size == size - 2

      vs.each do |v|
        raise ErrDimensionMismatch.new unless v.size == size
      end

      case size
      when 2
        Vector[-@elements[1], @elements[0]]
      when 3
        v = vs[0]
        Vector[v[2]*@elements[1] - v[1]*@elements[2],
          v[0]*@elements[2] - v[2]*@elements[0],
          v[1]*@elements[0] - v[0]*@elements[1]]
      else
        rows = [self, vs.to_a, Array.new(size) { |i| Vector.basis(size, i) }].flatten
        Matrix.rows(rows).laplace_expansion(row: size - 1)
      end
    end

    # ditto
    def cross(v)
      cross_product(v)
    end

    # Returns the inner product of this vector with the other.
    def inner_product(v)
      raise ErrDimensionMismatch.new if size != v.size
      map(v) { |v1, v2| v1 * v2 }.sum
    end

    # ditto
    def dot(v)
      inner_product(v)
    end

    # Iterate over the elements of this vector and `v` in conjunction.
    def each(v, &block)
      raise ErrDimensionMismatch.new if size != v.size
      size.times do |i|
        yield @elements[i], v[i]
      end
      self
    end

    # Returns the modulus (Pythagorean distance) of the vector.
    def magnitude
      Math.sqrt(@elements.reduce(0) { |v, e| v + e.abs2 })
    end

    # ditto
    def norm
      magnitude
    end

    # Returns a new vector with the same direction but with norm 1
    def normalize
      n = magnitude
      raise ZeroVectorError.new("Zero vectors can not be normalized") if n == 0
      self.coerce(Float64) / n
    end

    # ditto
    def r
      magnitude
    end

    # Returns a vector with entries rounded to the given precision.
    def round(ndigits = 0)
      map { |e| e.round(ndigits) }
    end

    # Attempt to coerce the elements in a vector to Complex with
    # `imag` as the imaginary number.
    def coerce(klass : Complex.class, imag : Number)
      els = @elements.map { |e| Complex.new(e, imag) }
      self.class.elements(els)
    end

    # Attempt to coerce the elements in a vector to BigInt with
    # an optional `base` value.
    def coerce(klass : BigInt.class, base = 10)
      els = @elements.map { |e| BigInt.new(e, base) }
      self.class.elements(els)
    end

    # Attempt to coerce the elements in a vector to BigRational
    # with the given `denominator`.
    def coerce(klass : BigRational.class, denominator : Int)
      els = @elements.map { |e| BigRational.new(e, denominator) }
      self.class.elements(els)
    end

    # The coerce method allows you to attempt to coerce the elements
    # in the matrix to another type.
    def coerce(klass : U.class) : Vector(U) forall U
      els = @elements.map { |e| klass.new(e).as(U) }
      self.class.elements(els)
    end

    # Returns the elements of the vector in an array.
    def to_a
      @elements.dup
    end

    # Return a single-column matrix from this vector.
    def to_matrix
      Matrix.column_vector(self)
    end

    def to_s
      "Vector{" + @elements.join(", ") + "}"
    end

    # Returns `true` if all elements are zero.
    def zero?
      all?(&:zero?)
    end

    def inspect
      "<#Vector(#{T}) [#{@elements.join(", ")}]>"
    end

    def unsafe_fetch(i)
      @elements.unsafe_fetch(i)
    end
  end
end
