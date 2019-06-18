require "json"
require "./vector"

module Apatite::LinearAlgebra
  class Matrix
    include Enumerable(Vector)
    include Indexable(Vector)
    include Comparable(Matrix)

    getter column_count : Int32

    getter row_count : Int32

    @buffer : Pointer(Vector)

    def initialize(rows, column_count : Int32? = nil)
      @buffer = rows.map { |r| Vector.create(r) }.to_a.to_unsafe
      @row_count = rows.size
      @column_count = column_count || rows[0].size
    end

    # Creates a new `Vector` instance from a `JSON::PullParser`
    def self.new(pull : JSON::PullParser)
      arr = [] of Vector
      new(pull) do |element|
        arr << element
      end
      rows(arr)
    end

    def self.new(pull : JSON::PullParser, &block)
      pull.read_array do
        yield Vector.new(pull)
      end
    end

    # Creates a matrix where each argument is a row.
    def self.[](*rows)
      rows(rows)
    end

    # Creates a matrix of size `row_count x column_count`. It fills the values by calling
    # the given block, passing the current row and column.
    def self.build(row_count, column_count = row_count, &block)
      raise ArgumentError.new if row_count < 0 || column_count < 0
      rows = Array.new(row_count) do |i|
        Vector.new(column_count) do |j|
          yield i, j
        end
      end
      Matrix.new(rows, column_count)
    end

    # Creates a single-column matrix where the values of that column are as given in column.
    def self.col_vector(column)
      Matrix.new([column].transpose, 1)
    end

    # Creates a matrix using `columns` as an array of column vectors.
    def self.columns(columns)
      rows(columns).transpose
    end

    # # Create a matrix by combining matrices entrywise, using the given block.
    # def self.combine(matrices : Array(Matrix), &block : Matrix -> Matrix -> Matrix)
    #   return Matrix.empty if matrices.empty?
    #   x = matrices.first
    #   matrices.each do |m|
    #     raise "Dimension mismatch" unless x.row_count == m.row_count && x.column_count == m.column_count
    #   end

    #   rows = Array.new(x.row_count) do |i|
    #     Vector.new(x.column_count) do |j|
    #       yield matrices.map { |m| m[i, j] }
    #     end
    #   end

    #   Matrix.new(rows, x.column_count)
    # end

    # def self.combine(*matrices, &block : Matrix -> Matrix)
    #   Matrix.combine(matrices, &block)
    # end

    # Creates a matrix where the diagonal elements are composed of `values`.
    def self.diagonal(values)
      size = values.size
      return Matrix.empty if size == 0

      rows = Array.new(size) do |j|
        row = Array.new(size, 0)
        row[j] = values[j]
        row
      end

      new rows
    end

    # :ditto:
    def self.diagonal(*values)
      Matrix.diagonal(values)
    end

    # Creates a empty matrix of `row_count x column_count`. At least one of
    # `row_count` or `column_count` must be 0.
    def self.empty(row_count = 0, column_count = 0)
      raise ArgumentError.new("One size must be 0") if column_count != 0 && row_count != 0
      raise ArgumentError.new("Negative size") if column_count < 0 || row_count < 0
      Matrix.new(([] of Vector) * row_count, column_count)
    end

    # Creates a new diagonal matrix of size `n` with ones in the diagonal
    # and zeros elsewhere.
    def self.eye(n)
      Matrix.diagonal([1] * n)
    end

    # TODO
    def self.hstack(x, *matrices)
    end

    # Creates a `n x n` identity matrix.
    def self.identity(n)
      scalar(n, 1)
    end

    # Creates a matrix of the given shape with random vectors.
    def self.random(num_rows, num_columns, range = nil)
      Matrix.build(num_rows, num_columns) do |i, j|
        rand(range || -1e+1..1e+1)
      end
    end

    # Creates a single-row matrix where the values of that row are as given in `row`.
    def self.row_vector(row)
      Matrix.new([row], 0)
    end

    # Creates a matrix where rows is an array of arrays, each of which is a row of the matrix.
    def self.rows(rows)
      size = rows[0]? ? rows[0].size : 0
      rows.each do |row|
        raise "Dimension mismatch: row size differs (#{row.size} should be #{size})" unless row.size == size
      end
      Matrix.new(rows, size)
    end

    # Creates an `n` by `n` diagonal matrix where each diagonal element is value.
    def self.scalar(n, value)
      Matrix.diagonal(Array.new(n, value))
    end

    # TODO
    def self.vstack(x, y)
    end

    # Creates a zero matrix.
    def self.zero(row_count, column_count = row_count)
      rows = Array.new(row_count) { Vector.new(column_count) }
      Matrix.new(rows, column_count)
    end

    def *(other : Matrix)
      raise "Dimension mismatch" if column_count != other.column_count

      rows = Array.new(row_count) do |i|
        Vector.new(other.column_count) do |j|
          (0...column_count).reduce(0.0) do |vij, k|
            vij + self[i, k] * other[k, j]
          end
        end
      end

      return Matrix.new(rows, other.column_count)
    end

    def *(int : Int)
      rows = self.rows.map do |row|
        row.map { |e| e * int }
      end
      Matrix.new(rows, column_count)
    end

    def *(ind : Indexable)
      m = column_vector
      r = self * m
      r.column(0)
    end

    def **(int)
      raise "Number can not the less than 1" unless int >= 1
      mat = self
      (int - 1).times do
        mat = mat * self
      end
      mat
    end

    def +(other : Matrix)
      raise "Dimension mismatch" if column_count != other.column_count

      rows = Array.new(row_count) do |i|
        Vector.new(other.column_count) do |j|
          self[i, j] + other[i, j]
        end
      end

      return Matrix.new(rows, other.column_count)
    end

    def +(vec : Indexable)
      vec = vec.is_a?(Vector) ? vec : Vector.create(vec)
      self + column_vector(vec)
    end

    def -(other : Matrix)
      raise "Dimension mismatch" if column_count != other.column_count

      rows = Array.new(row_count) do |i|
        Vector.new(other.column_count) do |j|
          self[i, j] - other[i, j]
        end
      end

      return Matrix.new(rows, other.column_count)
    end

    def -(vec : Indexable)
      vec = vec.is_a?(Vector) ? vec : Vector.create(vec)
      self + column_vector(vec)
    end

    def /(other : Matrix)
      self * other.inverse
    end

    def /(vec : Indexable)
      rows = self.rows.map { |row|
        row.map { |e| e / other }
      }
      return new_matrix rows, column_count
    end

    def ==(other : Matrix)
      return false unless Matrix === other &&
                          column_count == other.column_count # necessary for empty matrices
      rows == other.rows
    end

    # Returns element `(row, col)` of the matrix. Throws error on index error.
    def [](row : Int, col : Int)
      self[row][col]
    end

    # Returns element `(row, col)` of the matrix, or nil if the index is not found.
    def []?(row : Int, col : Int)
      v = fetch(row) { nil }
      v[col]? unless v.nil?
    end

    # Returns the adjugate of the matrix.
    def adjugate
      raise "Dimention mismatch: `Matrix#adjugate` requires a square matrix." unless square?
      Matrix.build(row_count, column_count) do |row, column|
        cofactor(column, row)
      end
    end

    # Returns the (row, column) cofactor which is obtained by multiplying the first minor by (-1)**(row + column)
    def cofactor(row, column)
      raise "cofactor of empty matrix is not defined" if empty?
      raise "Dimention mismatch: `Matrix#cofactor` requires a square matrix." unless square?

      det_of_minor = first_minor(row, column).determinant
      det_of_minor * (-1.0) ** (row + column)
    end

    # Returns column vector number `j` of the matrix as a `Vector` (starting at 0 like an array).
    def column?(j)
      return nil if j >= column_count || j < -column_count
      col = Array(Float64).new(row_count) { |i|
        rows[i][j]
      }
      Vector.create(col)
    end

    # Returns column vector number `j` of the matrix as a `Vector` (starting at 0 like an array).
    def column(j)
      raise "Index out of range" if j >= column_count || j < -column_count
      col = Array(Float64).new(row_count) { |i|
        rows[i][j]
      }
      Vector.create(col)
    end

    # Iterates over the specified column in the matrix, returning the Vector's items.
    def column(j, &block)
      return self if j >= column_count || j < -column_count
      row_count.times do |i|
        yield rows[i][j]
      end
      self
    end

    # Returns an array of the column vectors of the matrix. See `Vector`.
    def column_vectors
      Array(Vector).new(column_count) { |i|
        column(i)
      }
    end

    # def combine(*matrices, &block)
    #   Matrix.combine(self, matrices, &block)
    # end

    # Iterates over each column, yielding the column
    def each_column(&block)
      vectors = column_vectors.map { |vec| yield(vec) }
      @buffer = Matrix.columns(vectors).to_unsafe
      vectors
    end

    # Iterates over each row, yielding the row
    def each_row(&block)
      vectors = rows.map { |vec| yield(vec) }
      @buffer = Matrix.rows(vectors).to_unsafe
      vectors
    end

    # # Hadamard product
    # def hadamard_product(m)
    #   combine(m){|a, b| a * b}
    # end

    # # Returns a new matrix resulting by stacking horizontally the receiver with the given matrices
    # def hstack(*matrices)
    #   Matrix.hstack(self, *matrices)
    # end

    # Returns the inverse of the matrix.
    def inverse
      raise "Dimention mismatch: `Matrix#inverse` requires a square matrix." unless square? unless square?
      Matrix.identity(row_count).inverse_from(self)
    end

    # :nodoc:
    def inverse_from(src)
      last = row_count - 1.0
      a = src.to_a

      0.upto(last) do |k|
        i = k
        akk = a[k][k].abs
        (k + 1).upto(last) do |j|
          v = a[j][k].abs
          if v > akk
            i = j
            akk = v
          end
        end
        raise "Not regular" if akk == 0
        if i != k
          a[i], a[k] = a[k], a[i]
          rows[i], rows[k] = rows[k], rows[i]
        end
        akk = a[k][k]

        0.upto(last) do |ii|
          next if ii == k
          q = a[ii][k] / akk
          a[ii][k] = 0.0

          (k + 1).upto(last) do |j|
            a[ii][j] -= a[k][j] * q
          end
          0.upto(last) do |j|
            rows[ii][j] -= rows[k][j] * q
          end
        end

        (k + 1).upto(last) do |j|
          a[k][j] = a[k][j] / akk
        end
        0.upto(last) do |j|
          rows[k][j] = rows[k][j] / akk
        end
      end
      self
    end

    def determinant
      raise "Dimention mismatch: `Matrix#determinant` requires a square matrix." unless square?
      m = rows
      case row_count
      # Up to 4x4, give result using Laplacian expansion by minors.
      # This will typically be faster, as well as giving good results
      # in case of Floats
      when 0
        +1
      when 1
        +m[0][0]
      when 2
        +m[0][0] * m[1][1] - m[0][1] * m[1][0]
      when 3
        m0, m1, m2 = m
        +m0[0] * m1[1] * m2[2] - m0[0] * m1[2] * m2[1] \
          - m0[1] * m1[0] * m2[2] + m0[1] * m1[2] * m2[0] \
            + m0[2] * m1[0] * m2[1] - m0[2] * m1[1] * m2[0]
      when 4
        m0, m1, m2, m3 = m
        +m0[0] * m1[1] * m2[2] * m3[3] - m0[0] * m1[1] * m2[3] * m3[2] \
          - m0[0] * m1[2] * m2[1] * m3[3] + m0[0] * m1[2] * m2[3] * m3[1] \
            + m0[0] * m1[3] * m2[1] * m3[2] - m0[0] * m1[3] * m2[2] * m3[1] \
              - m0[1] * m1[0] * m2[2] * m3[3] + m0[1] * m1[0] * m2[3] * m3[2] \
                + m0[1] * m1[2] * m2[0] * m3[3] - m0[1] * m1[2] * m2[3] * m3[0] \
                  - m0[1] * m1[3] * m2[0] * m3[2] + m0[1] * m1[3] * m2[2] * m3[0] \
                    + m0[2] * m1[0] * m2[1] * m3[3] - m0[2] * m1[0] * m2[3] * m3[1] \
                      - m0[2] * m1[1] * m2[0] * m3[3] + m0[2] * m1[1] * m2[3] * m3[0] \
                        + m0[2] * m1[3] * m2[0] * m3[1] - m0[2] * m1[3] * m2[1] * m3[0] \
                          - m0[3] * m1[0] * m2[1] * m3[2] + m0[3] * m1[0] * m2[2] * m3[1] \
                            + m0[3] * m1[1] * m2[0] * m3[2] - m0[3] * m1[1] * m2[2] * m3[0] \
                              - m0[3] * m1[2] * m2[0] * m3[1] + m0[3] * m1[2] * m2[1] * m3[0]
      else
        # For bigger matrices, use an efficient and general algorithm.
        # Currently, we use the Gauss-Bareiss algorithm
        determinant_bareiss
      end
    end

    # Returns the determinant of the matrix, using
    # Bareiss' multistep integer-preserving gaussian elimination.
    # It has the same computational cost order O(n^3) as standard Gaussian elimination.
    # Intermediate results are fraction free and of lower complexity.
    # A matrix of Integers will have thus intermediate results that are also Integers,
    # with smaller bignums (if any), while a matrix of Float will usually have
    # intermediate results with better precision.
    #
    private def determinant_bareiss
      size = row_count
      last = size - 1
      a = to_a
      no_pivot = Proc(Int32).new { return 0 }
      sign = +1
      pivot = 1
      size.times do |k|
        previous_pivot = pivot
        if (pivot = a[k][k]) == 0
          switch = (k + 1...size).find(0) { |row|
            a[row][k] != 0
          }

          a[switch], a[k] = a[k], a[switch]
          pivot = a[k][k]
          sign = -sign
        end
        (k + 1).upto(last) do |i|
          ai = a[i]
          (k + 1).upto(last) do |j|
            ai[j] = (pivot * ai[j] - ai[k] * a[k][j]) / previous_pivot
          end
        end
      end
      sign * pivot
    end

    def first_minor(row, column)
      raise "first_minor of empty matrix is not defined" if empty?

      unless 0 <= row && row < row_count
        raise ArgumentError.new("invalid row (#{row.inspect} for 0..#{row_count - 1})")
      end

      unless 0 <= column && column < column_count
        raise ArgumentError.new("invalid column (#{column.inspect} for 0..#{column_count - 1})")
      end

      arrays = to_a.map(&.to_a)
      arrays.delete_at(row)
      arrays.each do |array|
        array.delete_at(column)
      end

      Matrix.new(arrays, column_count - 1)
    end

    # Returns the Laplace expansion along given row or column.
    def laplace_expansion(*, row = nil, column = nil)
      num = row || column

      if !num || (row && column)
        raise ArgumentError.new("exactly one the row or column arguments must be specified")
      end

      raise "Dimention mismatch: `Matrix#determinant` requires a square matrix." unless square?
      raise "laplace_expansion of empty matrix is not defined" if empty?

      unless 0 <= num && num < row_count
        raise ArgumentError.new("invalid num (#{num.inspect} for 0..#{row_count - 1})")
      end

      if row
        row(num).map_with_index { |e, k|
          e * cofactor(num, k)
        }.reduce(&.+)
      else
        column(num).map_with_index { |e, k|
          e * cofactor(k, num)
        }.reduce(&.+)
      end
    end

    def row(i, &block)
      rows.fetch(i) { return self }.each(&block)
      self
    end

    def row(i)
      Vector.create(rows.fetch(i) { [] of Float64 })
    end

    def rows
      rows = [] of Vector
      row_count.times do |i|
        rows << self[i - 1]
      end
      rows
    end

    def square?
      row_count == column_count
    end

    def transpose
      return Matrix.empty(column_count, 0) if row_count.zero?
      transposed = rows.map { |v| v.to_a }.transpose
      Matrix.new(transposed, row_count)
    end

    def to_s(io)
      if empty?
        "Matrix.empty(#{row_count}, #{column_count})"
      else
        io << "Matrix["

        io << map { |row|
          "{" + row.to_a.map { |e| e.to_s }.join(", ") + "}"
        }.join(", ")

        io << "]"
      end
    end

    def pretty_print(pp) : Nil
      pp.list("[", self, "]") do |vec|
        pp.group do
          vec.to_a.pretty_print(pp)
        end
      end
    end

    def to_json(json : JSON::Builder)
      json.array do
        each &.to_json(json)
      end
    end

    def to_unsafe
      @buffer
    end

    @[AlwaysInline]
    def unsafe_fetch(index : Int)
      @buffer[index]
    end

    # To be in compliance with `Indexable`
    private def size
      @row_count
    end
  end
end
