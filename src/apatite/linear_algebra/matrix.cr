require "json"
require "./vector"

module Apatite::LinearAlgebra
  class Matrix(T)
    include Enumerable(Vector)
    include Indexable(Vector)
    include Comparable(Matrix)

    protected getter rows : Array(Array(T))

    # Creates a matrix where each argument is a row.
    #
    # ```
    # Matrix[[25, 93], [-1, 66]]
    # # => [ 25, 93,
    # #      -1, 66 ]
    # ```
    def self.[](*rows)
      rows(rows, false)
    end

    # Creates a matrix where +rows+ is an array of arrays, each of which is a row
    # of the matrix.  If the optional argument +copy+ is false, use the given
    # arrays as the internal structure of the matrix without copying.
    #
    # ```
    # Matrix.rows([[25, 93], [-1, 66]])
    # # => [ 25, 93,
    # #      -1, 66 ]
    # ```
    def self.rows(rows : Indexable(Array(T)), copy = true)
      rows = rows.dup if copy
      rows = rows.to_a
      rows.map! do |row|
        row = row.dup if row
        row.to_a
      end
      size = (rows[0] || [] of T).size
      rows.each do |row|
        raise ErrDimensionMismatch.new("row size differs (#{row.size} should be #{size})") unless row.size == size
      end
      new(rows, size)
    end

    # Creates a matrix using +columns+ as an array of column vectors.
    #
    # ```
    # Matrix.columns([[25, 93], [-1, 66]])
    # # => [ 25, -1,
    # #      93, 66 ]
    # ```
    def self.columns(columns)
      rows(columns, false).transpose
    end

    # Creates a matrix of size +row_count+ x +column_count+.
    # It fills the values by calling the given block,
    # passing the current row and column.
    # Returns an enumerator if no block is given.
    #
    # ```
    # m = Matrix.build(2, 4) { |row, col| col - row }
    # # => Matrix[[0, 1, 2, 3], [-1, 0, 1, 2]]
    # m = Matrix.build(3) { rand }
    # # => a 3x3 matrix with random elements
    # ```
    def self.build(row_count, column_count = row_count, &block)
      row_count = row_count.to_i
      column_count = column_count.to_i
      raise ArgumentError.new if row_count < 0 || column_count < 0
      rows = Array(T).new(row_count) do |i|
        Array(T).new(column_count) do |j|
          yield i, j
        end
      end
      new(rows, column_count)
    end

    # Creates a matrix where the diagonal elements are composed of `values`.
    #
    # ```
    # Matrix.diagonal(9, 5, -3)
    # # =>  [ 9,  0,  0,
    # #       0,  5,  0,
    # #       0,  0, -3 ]
    # ```
    def self.diagonal(values : Indexable(T), dummy = nil)
      size = values.size
      return Matrix(T).empty if size == 0
      rows = Array(Array(T)).new(size) do |j|
        row = Array(T).new(size, T.new(0))
        row[j] = values[j]
        row
      end
      new(rows)
    end

    def self.diagonal(*values : T)
      diagonal(values, nil)
    end

    # Creates an +n+ by +n+ diagonal matrix where each diagonal element is
    # `value`.
    #
    # ```
    # Matrix.scalar(2, 5)
    # # => [ 5, 0,
    # #      0, 5 ]
    # ```
    def self.scalar(n, value : T)
      diagonal(Array(T).new(n, value))
    end

    # Creates an `n` by `n` identity matrix.
    #
    # ```
    # Matrix.identity(2)
    # # => [ 1, 0,
    # #      0, 1 ]
    # ```
    def self.identity(n : T)
      scalar(n, T.new(1))
    end

    # ditto
    def self.unit(n : T)
      identity(n)
    end

    # Creates a zero matrix.
    #
    # ```
    # Matrix.zero(2)
    # # => [ 0, 0,
    # #      0, 0 ]
    # ```
    def self.zero(row_count, column_count = row_count)
      rows = Array(T).new(row_count) { Array(T).new(column_count, T.new(0)) }
      new(rows, column_count)
    end

    # Creates a single-row matrix where the values of that row are as given in
    # `row`.
    #
    # ```
    # Matrix.row_vector([4,5,6])
    # # => [ 4, 5, 6 ]
    # ```
    def self.row_vector(row)
      row = row.to_a
      new([row])
    end

    # Creates a single-column matrix where the values of that column are as given
    # in `column`.
    #
    # ```
    # Matrix.column_vector([4,5,6])
    # # => [ 4,
    # #      5,
    # #      6 ]
    # ```
    def self.column_vector(column)
      column = column.to_a
      new([column].transpose, 1)
    end

    # Creates a empty matrix of `row_count` x `column_count`.
    # At least one of `row_count` or `column_count` must be 0.
    #
    # ```
    # m = Matrix(Int32).empty(2, 0)
    # m == Matrix[ [], [] ]
    # # => true
    # n = Matrix(Int32).empty(0, 3)
    # m * n
    # # => Matrix[[0, 0, 0], [0, 0, 0]]
    # ```
    def self.empty(row_count = 0, column_count = 0)
      raise ArgumentError.new("One size must be 0") if column_count != 0 && row_count != 0
      raise ArgumentError.new("Negative size") if column_count < 0 || row_count < 0

      new([[] of T] * row_count, column_count)
    end

    # Create a matrix by stacking matrices vertically
    #
    # ```
    # x = Matrix[[1, 2], [3, 4]]
    # y = Matrix[[5, 6], [7, 8]]
    # Matrix.vstack(x, y)
    # # => Matrix[[1, 2], [3, 4], [5, 6], [7, 8]]
    # ```
    def Matrix.vstack(x, *matrices)
      result = x.rows
      matrices.each do |m|
        m = m.is_a?(Matrix) ? m : rows(m)
        if m.column_count != x.column_count
          raise ErrDimensionMismatch.new("The given matrices must have #{x.column_count} columns, but one has #{m.column_count}")
        end
        result.concat(m.rows)
      end
      new(result, x.column_count)
    end

    # Create a matrix by stacking matrices horizontally
    #
    # ```
    # x = Matrix[[1, 2], [3, 4]]
    # y = Matrix[[5, 6], [7, 8]]
    # Matrix.hstack(x, y)
    # # => Matrix[[1, 2, 5, 6], [3, 4, 7, 8]]
    # ```
    def Matrix.hstack(x, *matrices)
      result = x.rows
      total_column_count = x.column_count

      matrices.each do |m|
        m = m.is_a?(Matrix) ? m : rows(m)
        if m.row_count != x.row_count
          raise ErrDimensionMismatch.new("The given matrices must have #{x.row_count} rows, but one has #{m.row_count}")
        end

        result.each_with_index do |row, i|
          row.concat m.rows[i]
        end

        total_column_count += m.column_count
      end

      new(result, total_column_count)
    end

    # Create a matrix by combining matrices entrywise, using the given block
    #
    # ```
    # x = Matrix[[6, 6], [4, 4]]
    # y = Matrix[[1, 2], [3, 4]]
    # Matrix.combine(x, y) {|a, b| a - b}
    # # => Matrix[[5, 4], [1, 0]]
    # ```
    def self.combine(*matrices, &block)
      return Matrix.empty if matrices.empty?

      matrices = matrices.map { |m| m = m.is_a?(Matrix) ? m : rows(m) }
      x = matrices.first
      matrices.each do |m|
        raise ErrDimensionMismatch.new unless x.row_count == m.row_count && x.column_count == m.column_count
      end

      rows = Array(T).new(x.row_count) do |i|
        Array(T).new(x.column_count) do |j|
          yield matrices.map{ |m| m[i,j] }
        end
      end

      new(rows, x.column_count)
    end

    # ditto
    def combine(*matrices, &block)
      Matrix.combine(self, *matrices, &block)
    end

    private def initialize(rows : Array(Array(T)), column_count = nil)
      # No checking is done at this point. rows must be an Array of Arrays.
      # column_count must be the size of the first row, if there is one,
      # otherwise it *must* be specified and can be any integer >= 0
      @rows = rows
      @column_count = column_count || rows[0].try &.size
    end

    # Returns element (`i`, `j`) of the matrix.  That is: row `i`, column `j`.
    # Throws if either index is not found.
    def [](i, j)
      @rows[i][j]
    end

    # Returns element (`i`, `j`) of the matrix.  That is: row `i`, column `j`.
    # Returns nil if either index is not found.
    def []?(i, j)
      @rows[i]?.try &.[j]?
    end

    # Set the value at index (`i`, `j`). That is: row `i`, column `j`.
    def []=(i, j, v : T)
      @rows[i][j] = v
    end

    # Returns the number of rows.
    def row_count
      @rows.size
    end

    # Returns the number of columns.
    getter column_count : Int32

    def unsafe_fetch(i)
      @rows.unsafe_fetch(i)
    end
  end
end
