require "./vector"

module Apatite
  class Matrix
    include Enumerable(Vector)
    include Indexable(Vector)
    include Comparable(Matrix)

    @col_count : Int32

    @buffer : Pointer(Vector)

    def initialize(rows : Array(Indexable(Number)), col_count : Int32 = rows[0].size)
      @buffer = rows.map { |r| Vector.create(r) }.to_unsafe
      @col_count = col_count
    end

    # Creates a matrix where each argument is a row.
    def self.[](*rows)
      rows(rows, false)
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
      rows(columns, false).transpose
    end

    # Create a matrix by combining matrices entrywise, using the given block.
    def self.combine(matrices, &block)
      return Matrix.empty if matrices.empty?
      x = matrices.first
      matrices.each do |m|
        rase "Dimension mismatch" unless x.row_count == m.row_count && x.column_count == m.column_count
      end

      rows = Array.new(x.row_count) do |i|
        Vector.new(x.column_count) do |j|
          yield matrices.map{|m| m[i,j]}
        end
      end
      new rows, x.column_count
    end

    def self.combine(*matrices, &block)
      Matrix.combine(matrices, &block)
    end

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

    # TODO
    def self.hstack(x, *matrices)
    end

    # Creates a `n x n` identity matrix.
    def self.identity(n)
      scalar(n, 1)
    end

    # Creates a single-row matrix where the values of that row are as given in `row`.
    def self.row_vector(row)
      Matrix.new([row])
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
  end
end
