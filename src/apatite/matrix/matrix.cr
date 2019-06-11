require "./vector"

module Apatite
  class Matrix(T) < Array(T)
    include Indexable(T)

    @rows : Int32

    @cols : Int32

    # Creates a Matrix with each element initialized as *value*.
    def self.of(value : T, rows : Int32, cols : Int32)
      Matrix(T).new(shape) { value }
    end

    # Creates a Matrix, invoking *initializer* with each pair of indices.
    def self.build(shape, &initializer : UInt32, UInt32 -> T)
      Matrix(T).new(shape) do |idx|
        i = (idx / N).to_u32
        j = (idx % N).to_u32
        initializer.call(i, j)
      end
    end

    # Creates a single-column `Matrix` from a `Vector`
    def self.col_vector(vector)
      col = vector.to_a
      Matrix(T).from(col, {col.size, 1})
    end

    # Creates a Matrix from elements contained within a StaticArray.
    #
    # The matrix will be filled rows first, such that an array of
    #
    #   [1, 2, 3, 4]
    #
    # becomes
    #
    #   | 1  2 |
    #   | 3  4 |
    #
    def self.from(list : Array(T), shape)
      raise("Not enough elements to fill matrix") if list.size < shape[0] * shape[1]

      Matrix(T).new(shape) do |idx|
        list[idx]
      end
    end

    # Creates a single-row `Matrix` from a `Vector`
    def self.row_vector(vector)
      row = vector.to_a
      Matrix(T).from(row, {1, row.size})
    end

    # Build a zero matrix (all elements populated with zero value of the type
    # isntance).
    def self.zero(shape)
      Matrix(T).new(shape) { T.zero }
    end

    # Build the idenity matrix for the instanced type and dimensions.
    #
    # `id` may be used to specify an identity element for the type. If unspecifed
    # a numeric identity will be assumed.
    # def self.identity(id = T.zero + 1, shape)
    #   {{ raise("Matrix dimensions must be square") unless M == N }}

    #   Matrix(T).(shape) do |i, j|
    #     i == j ? id : T.zero
    #   end
    # end

    # Creates Matrix, yielding the linear index for each element to provide an
    # initial value.
    def initialize(shape, &block : Int32 -> T)
      raise("Matrix dimensions must be positive") if shape[0] < 0 || shape[1] < 0
      @rows = shape[0]
      @cols = shape[1]
      @buffer = Pointer(T).malloc(size, &block)
    end

    # Equality. Returns `true` if each element in `self` is equal to each
    # corresponding element in *other*.
    def ==(other : Matrix(U)) forall U
      {% if other.rows == rows && other.cols == cols %}
        each_with_index do |e, i|
          return false unless e == other[i]
        end
        true
      {% else %}
        false
      {% end %}
    end

    # Equality with another object, or differently sized matrix. Always `false`.
    def ==(other)
      false
    end

    # Returns a new Matrix that is the result of performing a matrix addition with
    # *other*
    def +(other : Matrix)
      merge(other) { |a, b| a + b }
    end

    # Returns a new Matrix that is the result of performing a matrix subtraction
    # with *other*
    def -(other : Matrix)
      merge(other) { |a, b| a - b }
    end

    # Performs a matrix multiplication with *other*.
    def *(other : Matrix)
      raise("Dimension mismatch, cannot multiply a #{rows}x#{cols} by a #{other.rows}x#{other.cols}") unless cols == other.cols

      Matrix(typeof(self[0] * other[0])).build(other.rows, other.cols) do |i, j|
        pairs = row(i).zip other.col(j)
        pairs.map(&.product).sum
      end
    end

    # Performs a scalar multiplication with *other*.
    def *(other)
      map { |x| x * other }
    end

    # Retrieves the value of the element at *i*,*j*.
    #
    # Indicies are zero-based. Negative values may be passed for *i* and *j* to
    # enable reverse indexing such that `self[-1, -1] == self[M - 1, N - 1]`
    # (same behaviour as arrays).
    def [](i : Int, j : Int) : T
      idx = index i, j
      to_unsafe[idx]
    end

    # Sets the value of the element at *i*,*j*.
    def []=(i : Int, j : Int, value : T)
      idx = index i, j
      to_unsafe[idx] = value
    end

    # Gets the contents of row *i*.
    def row(i : Int)
      Vector.new(cols) { |j| self[i, j] }
    end

    # Gets the contents of column *j*.
    def col(j : Int)
      Vector.new(rows) { |i| self[i, j] }
    end

    # Yields the current element at *i*,*j* and updates the value with the
    # block's return value.
    def update(i, j, &block : T -> T)
      idx = index i, j
      to_unsafe[idx] = yield to_unsafe[idx]
    end

    # Apply a morphism to all elements, returning a new Matrix with the result.
    def map(&block : T -> U) forall U
      Matrix(U).new({rows, cols}) do |idx|
        block.call to_unsafe[idx]
      end
    end

    # ditto
    def map_with_indices(&block : T, UInt32, UInt32 -> U) forall U
      Matrix(U).from({rows, cols}) do |i, j|
        block.call self[i, j], i, j
      end
    end

    # ditto
    def map_with_index(&block : T, Int32 -> U) forall U
      Matrix(U).new({rows, cols}) do |idx|
        block.call to_unsafe[idx], idx
      end
    end

    # Apply an endomorphism to `self`, mutating all elements in place.
    def map!(&block : T -> T)
      each_with_index do |e, idx|
        to_unsafe[idx] = yield e
      end
      self
    end

    # Merge with another similarly dimensions matrix, apply the passed block to
    # each elemenet pair.
    def merge(other : Matrix(U), &block : T, U -> _) forall U
      raise("Dimension mismatch") unless other.rows == rows && other.cols == cols

      map_with_index do |e, i|
        block.call e, other[i]
      end
    end

    # Gets an `Vector` of `Vector` representing rows
    def row_vectors
      Vector.new(rows) { |i| row(i) }
    end

    # Gets an `Array` of `Vector` representing columns
    def col_vectors
      Vector.new(cols) { |i| col(i) }
    end

    # Creates a new matrix that is the result of inverting the rows and columns
    # of `self`.
    def transpose
      Matrix(T).build({cols, rows}) do |i, j|
        self[j, i]
      end
    end

    # Returns the dimensions of `self` as a tuple of `{rows, cols}`.
    def dimensions
      {rows, cols}
    end

    # Gets the capacity (total number of elements) of `self`.
    def size
      @rows * @cols
    end

    # Count of rows.
    def rows
      @rows
    end

    # Count of columns.
    def cols
      @cols
    end

    # Returns the element at the given linear index, without doing any bounds
    # check.
    #
    # Used by `Indexable`
    @[AlwaysInline]
    def unsafe_fetch(index : Int)
      to_unsafe[index]
    end

    # Returns the pointer to the underlying element data.
    def to_unsafe : Pointer(T)
      @buffer
    end

    # Map *i*,*j* coords to an index within the buffer.
    def index(i : Int, j : Int) : T
      i += rows if i < 0
      j += cols if j < 0

      raise IndexError.new if i < 0 || j < 0
      raise IndexError.new unless i < rows && j < cols

      i * cols + j
    end

    def inspect
      ::String.build do |s|
        s << "Matrix{" << self.join(", ") << "}"
      end
    end
  end
end
