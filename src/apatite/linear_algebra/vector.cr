module Apatite::LinearAlgebra
  # Represents a mathematical vector, and also constitutes a row or column
  # of a `Matrix`
  class Vector
    include Enumerable(Float64)
    include Indexable(Float64)
    include Comparable(Vector)

    # Cartesian unit vector I
    I = Vector.create([1.0, 0.0, 0.0])

    # Cartesian unit vector J
    J = Vector.create([0.0, 1.0, 0.0])

    # Cartesian unit vector K
    K = Vector.create([0.0, 0.0, 1.0])

    @buffer : Pointer(Float64)
    @capacity : Int32

    # Returns the number of elements in the vector
    getter size : Int32

    # Create a new empty `Vector`.
    def initialize
      @size = 0
      @capacity = 0
      @buffer = Pointer(Float64).null
    end

    # Creates a new empty `Vector` backed by a buffer that is initially
    # `initial_capacity` big.
    #
    # The *initial_capacity* is useful to avoid unnecessary reallocations
    # of the internal buffer in case of growth. If you have an estimate
    # of the maximum number of elements an vector will hold, the vector should
    # be initialized with that capacity for improved performance.
    #
    # ```
    # vec = Vector.new(5)
    # vec.size # => 0
    # ```
    def initialize(initial_capacity : Int)
      if initial_capacity < 0
        raise ArgumentError.new("Negative array size: #{initial_capacity}")
      end

      @size = 0
      @capacity = initial_capacity.to_i

      if initial_capacity == 0
        @buffer = Pointer(Float64).null
      else
        @buffer = Pointer(Float64).malloc(initial_capacity)
      end
    end

    # Creates a new `Vector` of the given *size* filled with the same *value* in each position.
    #
    # ```
    # Vector.new(3, 1.0) # => Vector{1.0, 1.0, 1.0}
    # ```
    def initialize(size : Int, value : Float64)
      if size < 0
        raise ArgumentError.new("Negative vector size: #{size}")
      end

      @size = size.to_i
      @capacity = size.to_i

      if size == 0
        @buffer = Pointer(Float64).null
      else
        @buffer = Pointer(Float64).malloc(size, value)
      end
    end

    # Creates a new `Vector` of the given *size* and invokes the given block once
    # for each index of `self`, assigning the block's value in that index.
    #
    # ```
    # Vector.new(3) { |i| (i + 1.0) ** 2.0 } # => Vector{1.0, 4.0, 9.0}
    #
    # vec = Vector.new(3) { 5.0 }
    # vec # => Vector{5.0, 5.0, 5.0}
    # ```
    def self.new(size : Int, &block : Int32 -> Float64)
      Vector.build(size) do |buffer|
        size.to_i.times do |i|
          buffer[i] = yield i
        end
        size
      end
    end

    # Creates a new `Vector`, allocating an internal buffer with the given *capacity*,
    # and yielding that buffer. The given block must return the desired size of the vector.
    #
    # This method is **unsafe**.
    #
    # ```
    # Vector.build(3) do |buffer|
    #   LibSome.fill_buffer_and_return_number_of_elements_filled(buffer)
    # end
    # ```
    def self.build(capacity : Int) : self
      vec = Vector.new(capacity)
      vec.size = (yield vec.to_unsafe).to_i
      vec
    end

    # Creates a new `Vector` from the elements of another `Indexable`
    # collection.
    #
    # ```
    # Vector.create([1, 2, 3]) # Vector{1.0, 2.0, 3.0}
    # ```
    def self.create(elements : Indexable(Number))
      vec = Vector.new
      elements.each do |el|
        vec.push(el.to_f64)
      end
      vec
    end

    # Generates a random vector of size `n` with elements
    # in `range`.
    def self.random(n, range = Float64::MIN..Float64::MAX)
      random = Random.new
      vec = Vector.new(n)
      n.times do
        vec.push random.rand(range)
      end
      vec
    end

    # Returns a standard basis n-vector.
    def self.basis(size, index)
      raise ArgumentError.new("invalid size (#{size} for 1..)") if size < 1
      raise ArgumentError.new("invalid index (#{index} for 0...#{size})") unless 0 <= index && index < size
      vec = Vector.new(size, 0.0)
      vec[index] = 1.0
      vec
    end

    # Create a new vector of size `n` filled with zeros.
    def self.zeros(n)
      Vector.new(n, 0.0)
    end

    # Create a new vector of size `n` filled with ones.
    def self.ones(n)
      Vector.new(n, 1.0)
    end

    def self.[](*array)
      Vector.create(array)
    end

    # Returns all elements that are within the given range.
    #
    # Negative indices count backward from the end of the vector (-1 is the last
    # element). Additionally, an empty vector is returned when the starting index
    # for an element range is at the end of the vector.
    #
    # Raises `IndexError` if the starting index is out of range.
    #
    # ```
    # v = Vector{1.0, 2.0, 3.0, 4.0, 5.0}
    # v[1..3]  # => Vector{2.0, 3.0, 4.0}
    # v[6..10] # raise IndexError
    # ```
    def [](range : Range(Int, Int))
      self[*Indexable.range_to_index_and_count(range, size)]
    end

    # Returns count or less (if there aren't enough) elements starting at the
    # given start index.
    #
    # Negative indices count backward from the end of the vector (-1 is the last
    # element). Additionally, an empty vector is returned when the starting index
    # for an element range is at the end of the vector.
    #
    # Raises `IndexError` if the starting index is out of range.
    #
    # ```
    # v = Vector{1.0, 2.0, 3.0, 4.0, 5.0}
    # v[1, 3]  # => Vector{2.0, 3.0, 4.0}
    # v[6, 10] # raise IndexError
    # ```
    def [](start : Int, count : Int)
      raise ArgumentError.new "Negative count: #{count}" if count < 0

      if start == size
        return Vector.new
      end

      start += size if start < 0
      raise IndexError.new unless 0 <= start <= size

      if count == 0
        return Vector.new
      end

      count = Math.min(count, size - start)

      Vector.build(count) do |buffer|
        buffer.copy_from(@buffer + start, count)
        count
      end
    end

    # Sets the given value at the given index.
    #
    # Negative indices can be used to start counting from the end of the array.
    # Raises `IndexError` if trying to set an element outside the array's range.
    #
    # ```
    # vec = Vector{1.0, 2.0, 3.0}
    # vec[0] = 5.0
    # p vec # => Vec{5.0, 2.0, 3.0}
    #
    # vec[3] = 5.0 # raises IndexError
    # ```
    @[AlwaysInline]
    def []=(index : Int, value)
      index = check_index_out_of_bounds index
      @buffer[index] = value.to_f64
    end

    # Replaces a subrange with a single value. All elements in the range
    # `index...index+count` are removed and replaced by a single element
    # *value*.
    #
    # If *count* is zero, *value* is inserted at *index*.
    #
    # Negative values of *index* count from the end of the vector.
    #
    # ```
    # vec = Vector{1.0, 2.0, 3.0, 4.0, 5.0}
    # vec[1, 3] = 6.0
    # vec # => Vector{1.0, 6.0, 5.0}
    #
    # vec = Vector{1.0, 2.0, 3.0, 4.0, 5.0}
    # vec[1, 0] = 6.0
    # vec # => Vector{1.0, 6.0, 2.0, 3.0, 4.0, 5.0}
    # ```
    def []=(index : Int, count : Int, value)
      raise ArgumentError.new "Negative count: #{count}" if count < 0

      value = value.to_f64
      index = check_index_out_of_bounds index
      count = (index + count <= size) ? count : size - index

      case count
      when 0
        insert index, value
      when 1
        @buffer[index] = value
      else
        diff = count - 1
        (@buffer + index + 1).move_from(@buffer + index + count, size - index - count)
        (@buffer + @size - diff).clear(diff)
        @buffer[index] = value
        @size -= diff
      end

      value
    end

    # Replaces a subrange with a single value.
    #
    # ```
    # vec = Vector{1.0, 2.0, 3.0, 4.0, 5.0}
    # vec[1..3] = 6.0
    # vec # = Vector{1.0, 6.0, 5.0}
    #
    # vec = Vector{1.0, 2.0, 3.0, 4.0, 5.0}
    # vec[1...1] = 6
    # vec # = Vector{1.0, 6.0, 2.0, 3.0, 4.0, 5.0}
    # ```
    def []=(range : Range(Int, Int), value)
      self[*Indexable.range_to_index_and_count(range, size)] = value.to_f64
    end

    # Replaces a subrange with the elements of the given vector.
    #
    # ```
    # vec = Vector{1.0, 2.0, 3.0, 4.0, 5.0}
    # vec[1, 3] = Vector{6.0, 7.0, 8.0}
    # vec # = Vector{1.0, 6.0, 7.0, 8.0, 5.0}
    #
    # vec = Vector{1.0, 2.0, 3.0, 4.0, 5.0}
    # vec[1, 3] = Vector{6.0, 7.0}
    # vec # = Vector{1.0, 6.0, 7.0, 5.0}
    # ```
    def []=(index : Int, count : Int, values : Vector)
      raise ArgumentError.new "Negative count: #{count}" if count < 0

      index = check_index_out_of_bounds index
      count = (index + count <= size) ? count : size - index
      diff = values.size - count

      if diff == 0
        # Replace values directly
        (@buffer + index).copy_from(values.to_unsafe, values.size)
      elsif diff < 0
        # Need to shrink
        diff = -diff
        (@buffer + index).copy_from(values.to_unsafe, values.size)
        (@buffer + index + values.size).move_from(@buffer + index + count, size - index - count)
        (@buffer + @size - diff).clear(diff)
        @size -= diff
      else
        # Need to grow
        resize_to_capacity(Math.pw2ceil(@size + diff))
        (@buffer + index + values.size).move_from(@buffer + index + count, size - index - count)
        (@buffer + index).copy_from(values.to_unsafe, values.size)
        @size += diff
      end

      values
    end

    # Combined comparison operator. Returns *0* if `self` equals *other*, *1* if
    # `self` is greater than *other* and *-1* if `self` is smaller than *other*.
    #
    # It compares the elements of both vectors in the same position using the
    # `<=>` operator.  As soon as one of such comparisons returns a non-zero
    # value, that result is the return value of the comparison.
    #
    # If all elements are equal, the comparison is based on the size of the vectors.
    #
    # ```
    # Vector{8.0} <=> Vector(1.0, 2.0, 3.0} # => 1
    # Vector{2.0} <=> Vector{4.0, 2.0, 3.0} # => -1
    # Vector{1.0, 2.0} <=> Vector{1.0, 2.0} # => 0
    # ```
    def <=>(other)
      min_size = Math.min(size, other.size)
      0.upto(min_size - 1) do |i|
        n = @buffer[i] <=> other.to_unsafe[i]
        return n if n != 0
      end
      size <=> other.size
    end

    # Alias for `#push`
    def <<(value : Float64)
      push(value)
    end

    def ==(other : Vector)
      equals?(other) { |x, y| x == y }
    end

    # :nodoc:
    def ==(other)
      false
    end

    def +(other)
      add(other)
    end

    def -(other)
      subtract(other)
    end

    def *(other)
      multiply(other)
    end

    def clone
      Vector.create(@elements.clone)
    end

    # Invokes the given block for each element of `self`.
    def map(&block)
      Vector.new(size) { |i| yield @buffer[i] }
    end

    # Returns true if all vectors are linearly independent.
    def independent?(*vs)
      vs.each do |v|
        raise "Dimension mismatch. Vectors not all the same size." unless v.size == vs.first.size
      end
      return false if vs.size > sv.first.size
      Matrix[*vs].rank.equal?(vs.count)
    end

    # Invokes the given block for each element of `self`, replacing the element
    # with the value returned by the block. Returns `self`.
    #
    # ```
    # vec = Vector{1.0, 2.0, 3.0}
    # vec.map! { |x| x * x }
    # a # => Vector{1.0, 4.0, 9.0}
    # ```
    def map!
      @buffer.map!(size) { |e| yield e }
      self
    end

    # Optimized version of `Enumerable#map_with_index`.
    def map_with_index(&block)
      Vector.new(size) { |i| yield @buffer[i], i }
    end

    # Like `map_with_index`, but mutates `self` instead of allocating a new object.
    def map_with_index!(&block)
      to_unsafe.map_with_index!(size) { |e, i| yield e, i }
      self
    end

    # Returns the magnitude/euclidian norm of this vector.
    #
    # [https://en.wikipedia.org/wiki/Euclidean_distance](https://en.wikipedia.org/wiki/Euclidean_distance)
    def magnitude
      sum = reduce(0.0) { |acc, e| acc += e * e }
      Math.sqrt(sum)
    end

    # Returns the `ith` element of the vector. Returns `nil` if `i`
    # is out of bounds. Indexing starts from 1.
    def e(i)
      (i < 1 || i > @size) ? nil : self[i - 1]
    end

    # Returns a new vector created by normalizing this one
    # to have a magnitude of `1`. If the vector is a zero
    # vector, it will not be modified.
    def to_unit_vector
      r = magnitude
      r == 0 ? dup : map { |x| x.to_f64 / r }
    end

    # Returns the angle between this vector and another in radians.
    # If the vectors are mirrored across their axes this will return `nil`.
    def angle_from(vector)
      v = vector.is_a?(Vector) ? vector : Vector.create(vector)

      unless size == v.size
        raise "Cannot compute the angle between vectors with different dimensionality"
      end

      dot = 0_f64
      mod1 = 0_f64
      mod2 = 0_f64

      zip(vector).each do |x, v|
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
    def parallel_to?(vector)
      angle = angle_from(vector)
      angle <= Apatite.precision
    end

    # Returns whether the vectors are antiparallel to each other.
    def antiparallel_to?(vector)
      angle = angle_from(vector)
      (angle - Math::PI).abs <= Apatite.precision
    end

    # Returns whether the vectors are perpendicular to each other.
    def perpendicular_to?(vector)
      (dot(vector)).abs <= Apatite.precision
    end

    # When the input is a number, this returns the result of adding
    # it to all vector elements. When it's a vector, the vectors
    # will be added together.
    def add(value)
      run_binary_op(value) { |a, b| a + b }
    end

    # When the input is a number, this returns the result of subtracting
    # it to all vector elements. When it's a vector, the vectors
    # will be subtracted.
    def subtract(value)
      run_binary_op(value) { |a, b| a - b }
    end

    # When the input is a number, this returns the result of multiplying
    # it to all vector elements. When it's a vector, the vectors
    # will be element-wise multiplied.
    def multiply(value)
      run_binary_op(value) { |a, b| a * b }
    end

    # Returns the sum of all elements in the vector.
    def sum
      reduce(0) { |acc, i| acc + i }
    end

    # Returns the cross product of this vector with the others.
    #
    # ```
    # v1 = Vector{1.0, 0.0, 0.0}
    # v2 = Vector{0.0, 1.0, 0.0}
    # v1.cross(v2) => Vector{0.0, 0.0, 1.0}
    # ```
    def cross(*vs)
      raise "cross product is not defined on vectors of dimension #{size}" unless size >= 2
      raise ArgumentError.new("wrong number of arguments (#{vs.size} for #{size - 2})") unless vs.size == size - 2
      vs.each do |v|
        raise "Dimension mismatch. Vectors not all the same size." unless v.size == size
      end
      case size
      when 2
        Vector[-@buffer[1], @buffer[0]]
      when 3
        v = vs[0]
        Vector[v[2] * @buffer[1] - v[1] * @buffer[2],
          v[0] * @buffer[2] - v[2] * @buffer[0],
          v[1] * @buffer[0] - v[0] * @buffer[1]]
      else
        # TODO
        # rows = [self, *vs, Vector.new(size) {|i| Vector.basis(size: size, index: i) }]
        # Matrix.rows(rows).laplace_expansion(row: size - 1)
      end
    end

    # Returns a new vector with the first `n` elements removed from
    # the beginning.
    def chomp(n)
      elements = [] of Float64
      each_with_index { |e, i| elements << e if i >= n }
      Vector.create(elements)
    end

    # Returns a vector containing only the first `n` elements.
    def top(n)
      elements = [] of Float64
      each_with_index { |e, i| elements << e if i < n }
      Vector.create(elements)
    end

    # Returns a new vector with the provided `elements` concatenated
    # on the end.
    def augment(elements)
      elements = elements.is_a?(Vector) ? elements : Vector.create(elements)
      concat(elements)
    end

    # Return a new `Vector` with the log of every item in `self`.
    def log
      map { |x| Math.log(x) }
    end

    # Get the product of all elements in this vector.
    def product
      reduce { |acc, v| acc *= v }
    end

    # Get the scalar (dot) product of this vector with `vector`.
    #
    # [https://en.wikipedia.org/wiki/Scalar_product](https://en.wikipedia.org/wiki/Scalar_product)
    def dot(other)
      other = other.is_a?(Vector) ? other : Vector.create(other)
      unless size == other.size
        raise "Cannot compute the dot product of vectors with different dimensionality"
      end

      product = 0
      (0...size).each do |i|
        product += self[i] * other[i]
      end

      product
    end

    # Returns the (absolute) largest element in this vector.
    def max
      reduce { |acc, i| i.abs > acc.abs ? i : acc }
    end

    # Gets the index of the largest element in this vector.
    def max_index
      idx = 0
      each_with_index { |e, i| idx = e.abs > self[idx].abs ? i : idx }
      idx
    end

    # Creates a single-row matrix from this vector.
    def covector
      Matrix.row_vector(self)
    end

    # Returns a diagonal `Matrix` with the vectors elements as its
    # diagonal elements.
    def to_diagonal_matrix
      Matrix::Diagonal.new(elements)
    end

    # Gets the result of rounding the elements of the vector.
    def round
      map { |x| x.round }
    end

    # Transpose this vector into a 1xn `Matrix`
    def transpose
      Matrix.col_vector(self)
    end

    # Returns a copy of the vector with elements set to `value` if
    # they differ from it by less than `Apetite.precision`
    def snap_to(value)
      map { |y| (y - x).abs <= Apetite.precision ? value : y }
    end

    # Gets this vector's distance from the argument, when considered
    # a point in space.
    def distance_from(obj)
      if object.is_a?(Plane) || object.is_a?(Line)
        return object.distance_from(self)
      end

      v = elements.is_a?(Vector) ? elements.elements : elements
      unless v.size == @elements.size
        return nil
      end

      sum = 0
      part = 0
      each_with_index do |x, i|
        part = x - v[i - 1]
        sum += part * part
      end
      Math.sqrt(sum)
    end

    # Returns true if the vector is a point on the given line
    def lies_on(line)
      line.contains(self)
    end

    # Returns true if the vector is a point on the given plane.
    def lies_in(plane)
      plane.contains(self)
    end

    def push(value : Float64)
      check_needs_resize
      @buffer[@size] = value
      @size += 1
      self
    end

    def push(*values : Float64)
      new_size = @size + values.size
      resize_to_capacity(Math.pw2ceil(new_size)) if new_size > @capacity
      values.each_with_index do |value, i|
        @buffer[@size + i] = value
      end
      @size = new_size
      self
    end

    # Rotates the vector about the given `object`. The object should
    # be a point if the vector is 2D, and a line if it is 3D. Be
    # careful with line directions!
    def rotate(t, object)
      # TODO
    end

    # Returns the result of reflecting the point in the given `object`
    # (point, line, or plane).
    def reflection_in(object)
      if object.is_a?(Plane) || object.is_a?(Line)
        # object is a plane or line
        p = @elements.dup
        c = object.point_closest_to(p).elements
        return Vector.create([
          C[0] + (C[0] - P[0]),
          C[1] + (C[1] - P[1]),
          C[2] + (C[2] - (P[2] || 0)),
        ])
      end

      # object is a point
      q = object.is_a?(Vector) ? object.elements : object
      unless @elements.size == q.size
        return nil
      end

      map_with_index { |x, i| q[i - 1] + (q[i - 1] - x) }
    end

    # Sums the numbers in the vector and returns a sigmoid value
    # across the whole vector.
    def sigmoid
      LinearAlgebra.sigmoid(sum)
    end

    # Utility to make sure vectors are 3D. If they are 2D, a zero
    # z-component is added.
    def to_3d
      v = dup
      case v.elements.size
      when 3
        break
      when 2
        v.elements.push(0)
      else
        return nil
      end
      return v
    end

    def set_elements(elements)
      @elements = elements.is_a?(Vector) ? elements.elements : elements
      self
    end

    def concat(other : Vector)
      other_size = other.size
      new_size = size + other_size
      if new_size > @capacity
        resize_to_capacity(Math.pw2ceil(new_size))
      end

      (@buffer + @size).copy_from(other.to_unsafe, other_size)
      @size = new_size

      self
    end

    def to_a
      Array(Float64).new(size) { |i| self[i] }
    end

    def to_s(io)
      io << "{"
      join ", ", io, &.inspect(io)
      io << "}"
    end

    def pretty_print(pp) : Nil
      pp.list("Vector{", self, "}")
    end

    @[AlwaysInline]
    def unsafe_fetch(index : Int)
      @buffer[index]
    end

    # Returns a pointer to the internal buffer where `self`'s elements are stored.
    #
    # This method is **unsafe** because it returns a pointer, and the pointed might eventually
    # not be that of `self` if the array grows and its internal buffer is reallocated.
    #
    # ```
    # vec = Vector{1.0, 2.0, 3.0}
    # vec.to_unsafe[0] # => 1.0
    # ```
    def to_unsafe : Pointer(Float64)
      @buffer
    end

    # Removes all elements from self.
    #
    # ```
    # vec = Vector{1.0, 2.0, 3.0}
    # vec.clear # => Vector{}
    # ```
    def clear
      @buffer.clear(@size)
      @size = 0
      self
    end

    def zero?
      all?(&.zero?)
    end

    protected def size=(size : Int)
      @size = size.to_i
    end

    private def check_needs_resize
      double_capacity if @size == @capacity
    end

    private def double_capacity
      resize_to_capacity(@capacity == 0 ? 3 : (@capacity * 2))
    end

    private def resize_to_capacity(capacity)
      @capacity = capacity
      if @buffer
        @buffer = @buffer.realloc(@capacity)
      else
        @buffer = Pointer(Float64).malloc(@capacity)
      end
    end

    # Call a block on the value
    private def run_binary_op(value, &block : (T, T) -> T)
      if value.is_a?(Number)
        return map { |v| yield(v, value) }
      end

      values = value.is_a?(Vector) ? value : Vector.create(value)

      unless size == values.size
        raise "Cannot perform operations on vectors with different dimensions."
      end

      map_with_index { |x, i| yield(x, values[i]) }
    end
  end
end
