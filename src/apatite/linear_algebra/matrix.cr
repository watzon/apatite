require "json"
require "./vector"
require "./matrix/eigenvalue_decomposition"
require "./matrix/lup_decomposition"

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
      rows.each_with_index do |row, i|
        raise ErrDimensionMismatch.new("row size differs (row at index `#{i}` should contain #{size} elements, instead has #{row.size})") unless row.size == size
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
    def self.build(row_count, column_count = row_count, &block : Int32, Int32 -> T)
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
    def self.identity(n)
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
    def self.vstack(x, *matrices)
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
    def self.hstack(x, *matrices)
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

    # :nodoc:
    protected def initialize(rows : Array(Array(T)), column_count = nil)
      # No checking is done at this point. rows must be an Array of Arrays.
      # column_count must be the size of the first row, if there is one,
      # otherwise it *must* be specified and can be any integer >= 0
      @rows = rows
      @column_count = column_count || rows[0].try &.size
    end

    # Returns row `i` of the matrix as an Array. Raises if the
    # index is not found.
    def [](i)
      @rows[i]
    end

    # Returns row `i` of the matrix as an Array. Returns nil if the
    # index is not found.
    def []?(i)
      @rows[i]?
    end

    # Returns element (`i`, `j`) of the matrix.  That is: row `i`, column `j`.
    # Raises if either index is not found.
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

    # Returns row vector number `i` of the Matrix as a Vector (starting
    # at 0 like a good boy). Raises if the row doesn't exist.
    def row(i)
      raise IndexError.new if i >= row_count || i < -row_count
      Vector.elements(self[i])
    end

    # Returns a block which yields every Vector in the row (starting at 0).
    def row(i, &block : Vector ->)
      row(i).each(&block)
    end

    # Returns row vector number `i` of the Matrix as a Vector (starting
    # at 0 like a good boy). Returns nil if the row doesn't exist.
    def row?(i)
      row(i)
    rescue IndexError
      nil
    end

    # Returns column vector `j` of the Matrix as a Vector (starting at 0).
    # Raises if the column doesn't exist.
    def column(j)
      raise IndexError.new if j >= column_count || j < -column_count
      col = Array(T).new(row_count) do |i|
        @rows[i][j]
      end
      Vector.elements(col, false)
    end

    # Returns column vector `j` of the Matrix as a Vector (starting at 0).
    # Returns nil if the column doesn't exist.
    def column?(j)
      column(j)
    rescue IndexError
      nil
    end

    # Returns a block which yields every item in column `j` of the Matrix.
    def column(j, &block : T ->)
      column(j).each(&block)
    end

    # Returns a Matrix that is the result of iteration of the given block
    # over all elements in the matrix.
    def map(&block : T -> T)
      rows = @rows.map { |row| row.map(&block) }
      Matrix.new(rows, column_count)
    end

    # Yields all elements of the matrix, starting with those of the first row,
    # or returns an Enumerator if no block given.
    # Elements can be restricted by passing an argument:
    # * :all (default): yields all elements
    # * :diagonal: yields only elements on the diagonal
    # * :off_diagonal: yields all elements except on the diagonal
    # * :lower: yields only elements on or below the diagonal
    # * :strict_lower: yields only elements below the diagonal
    # * :strict_upper: yields only elements above the diagonal
    # * :upper: yields only elements on or above the diagonal
    #
    # ```
    # Matrix[ [1,2], [3,4] ].each { |e| puts e }
    # # => prints the numbers 1 to 4
    # Matrix[ [1,2], [3,4] ].each(:strict_lower).to_a # => [3]
    # ```
    def each(which = :all, &block : T ->)
      last = column_count
      case which.to_s
      when "all"
        @rows.each do |row|
          row.each(&block)
        end
      when "diagonal"
        @rows.each_with_index do |row, row_index|
          yield row.fetch(row_index){ return self }
        end
      when "off_diagonal"
        @rows.each_with_index do |row, row_index|
          column_count.times do |col_index|
            yield row[col_index] unless row_index == col_index
          end
        end
      when "lower"
        @rows.each_with_index do |row, row_index|
          0.upto([row_index, last].min) do |col_index|
            yield row[col_index]
          end
        end
      when "strict_lower"
        @rows.each_with_index do |row, row_index|
          [row_index, column_count].min.times do |col_index|
            yield row[col_index]
          end
        end
      when "strict_upper"
        @rows.each_with_index do |row, row_index|
          (row_index+1).upto(last - 1) do |col_index|
            yield row[col_index]
          end
        end
      when "upper"
        @rows.each_with_index do |row, row_index|
          row_index.upto(last - 1) do |col_index|
            yield row[col_index]
          end
        end
      else
        raise ArgumentError.new("expected #{which.inspect} to be one of :all, :diagonal, :off_diagonal, :lower, :strict_lower, :strict_upper or :upper")
      end
    end

    # Same as #each, but the row index and column index in addition to the element
    #
    # ```
    # Matrix[ [1,2], [3,4] ].each_with_index do |e, row, col|
    # puts "#{e} at #{row}, #{col}"
    # end
    # # => Prints:
    # #    1 at 0, 0
    # #    2 at 0, 1
    # #    3 at 1, 0
    # #    4 at 1, 1
    # ```
    def each_with_index(which = :all, &block : T, Int32, Int32 ->)
      last = column_count
      case which.to_s
      when "all"
        @rows.each_with_index do |row, row_index|
          row.each_with_index do |e, col_index|
            block.call(e, row_index, col_index)
          end
        end
      when "diagonal"
        @rows.each_with_index do |row, row_index|
          block.call(row.fetch(row_index){return self}, row_index, row_index)
        end
      when "off_diagonal"
        @rows.each_with_index do |row, row_index|
          column_count.times do |col_index|
            block.call(row[col_index], row_index, col_index)
          end
        end
      when "lower"
        @rows.each_with_index do |row, row_index|
          0.upto([row_index, last].min) do |col_index|
            block.call(row[col_index], row_index, col_index)
          end
        end
      when "strict_lower"
        @rows.each_with_index do |row, row_index|
          [row_index, column_count].min.times do |col_index|
            block.call(row[col_index], row_index, col_index)
          end
        end
      when "strict_upper"
        @rows.each_with_index do |row, row_index|
          (row_index+1).upto(last - 1) do |col_index|
            block.call(row[col_index], row_index, col_index)
          end
        end
      when "upper"
        @rows.each_with_index do |row, row_index|
          row_index.upto(last - 1) do |col_index|
            block.call(row[col_index], row_index, col_index)
          end
        end
      else
        raise ArgumentError.new("expected #{which.inspect} to be one of :all, :diagonal, :off_diagonal, :lower, :strict_lower, :strict_upper or :upper")
      end
    end

    SELECTORS = {all: true, diagonal: true, off_diagonal: true, lower: true, strict_lower: true, strict_upper: true, upper: true}

    # The index method is specialized to return the index as {row, column}
    # It also accepts an optional `selector` argument, see `#each` for details.
    #
    # ```
    # Matrix[ [1,1], [1,1] ].index(1, :strict_lower)
    # # => {1, 0}
    # ```
    def index(i, selector = :all)
      res = nil
      each_with_index(selector) do |e, row_index, col_index|
        if e == i
          res = {row_index, col_index}
          next
        end
      end
      res
    end

    # Returns the index as {row, column}, using `&block` to filter the
    # result. It also accepts an optional `selector` argument, see
    # `#each` for details.
    #
    # ```
    # Matrix[ [1,2], [3,4] ].index(&.even?)
    # # => {0, 1}
    # ```
    def index(selector = :all, &block : T -> Bool)
      res = nil
      each_with_index(selector) do |e, row_index, col_index|
        if block.call(e)
          res = {row_index, col_index}
          next
        end
      end
      res
    end

    # Returns a section of the Matrix.
    #
    # ```
    # Matrix.diagonal(9, 5, -3).minor(0..1, 0..2)
    # # => [ 9, 0, 0,
    # #      0, 5, 0 ]
    # ```
    def minor(row_range : Range, col_range : Range)
      from_row = row_range.first
      from_row += row_count if from_row < 0
      to_row = row_range.end
      to_row += row_count if to_row < 0
      to_row += 1 unless row_range.excludes_end?
      size_row = to_row - from_row

      from_col = col_range.first
      from_col += column_count if from_col < 0
      to_col = col_range.end
      to_col += column_count if to_col < 0
      to_col += 1 unless col_range.excludes_end?
      size_col = to_col - from_col

      return nil if from_row > row_count || from_col > column_count || from_row < 0 || from_col < 0

      rows = @rows[from_row, size_row].map do |row|
        row[from_col, size_col]
      end

      Matrix.new(rows, [column_count - from_col, size_col].min)
    end

    # Returns a section of the Matrix.
    #
    # ```
    # Matrix.diagonal(9, 5, -3).minor(0, 2, 0, 3)
    # # => [ 9, 0, 0,
    # #      0, 5, 0 ]
    # ```
    def minor(from_row : Int, nrows : Int, from_col : Int, ncols : Int)
      return nil if nrows < 0 || ncols < 0
      from_row += row_count if from_row < 0
      from_col += column_count if from_col < 0

      return nil if from_row > row_count || from_col > column_count || from_row < 0 || from_col < 0

      rows = @rows[from_row, nrows].map do |row|
        row[from_col, ncols]
      end

      Matrix.new(rows, [column_count - from_col, ncols].min)
    end

    # Returns the submatrix obtained by deleting the specified row and column.
    #
    # ```
    # Matrix.diagonal(9, 5, -3, 4).first_minor(1, 2)
    # # => [ 9, 0, 0,
    # #      0, 0, 0,
    # #      0, 0, 4 ]
    # ```
    def first_minor(row, column)
      raise "first_minor of empty matrix is not defined" if empty?

      unless 0 <= row && row < row_count
        raise ArgumentError.new("invalid row (#{row.inspect} for 0..#{row_count - 1})")
      end

      unless 0 <= column && column < column_count
        raise ArgumentError.new("invalid column (#{column.inspect} for 0..#{column_count - 1})")
      end

      arrays = to_a
      arrays.delete_at(row)
      arrays.each do |array|
        array.delete_at(column)
      end

      Matrix.new(arrays, column_count - 1)
    end

    # Returns the (row, column) cofactor which is obtained by multiplying
    # the first minor by (-1)**(row + column).
    #
    # ```
    # Matrix.diagonal(9, 5, -3, 4).cofactor(1, 1)
    # # => -108
    # ```
    def cofactor(row, column)
      raise "cofactor of empty matrix is not defined" if empty?
      raise ErrDimensionMismatch.new unless square?

      det_of_minor = first_minor(row, column).determinant
      det_of_minor * (-1) ** (row + column)
    end

    # Returns the adjugate of the matrix.
    #
    # Matrix[ [7,6],[3,9] ].adjugate
    # # => [ 9, -6,
    # #     -3,  7 ]
    # ```
    def adjugate
      raise ErrDimensionMismatch.new unless square?
      Matrix.build(row_count, column_count) do |row, column|
        cofactor(column, row)
      end
    end

    # Returns the Laplace expansion along given row or column.
    #
    # ```
    # Matrix[[7,6], [3,9]].laplace_expansion(column: 1)
    # # => 45
    #
    # Matrix[[Vector[1, 0], Vector[0, 1]], [2, 3]].laplace_expansion(row: 0)
    # # => Vector[3, -2]
    # ```
    def laplace_expansion(*, row = nil, column = nil)
      num = row || column

      if !num || (row && column)
        raise ArgumentError.new("exactly one the row or column arguments must be specified")
      end

      raise ErrDimensionMismatch.new unless square?
      raise "laplace_expansion of empty matrix is not defined" if empty?

      unless 0 <= num && num < row_count
        raise ArgumentError, "invalid num (#{num.inspect} for 0..#{row_count - 1})"
      end

      if row
        row(num).map_with_index do |e, k|
          e * cofactor(num, k)
        end.reduce(&.+)
      else
        col(num).map_with_index do |e, k|
          e * cofactor(k, num)
        end.reduce(&.+)
      end
    end

    # Swaps `row1` and `row2`
    def swap_rows(row1, row2)
      raise IndexError.new if row1 >= row_count || row2 >= row_count
      row1 += row_count if row1 < 0
      row2 += row_count if row2 < 0
      raise IndexError.new if row1 < 0 || row2 < 0
      column_count.times do |i|
        self[row1, i], self[row2, i] = self[row2, i], self[row1, i]
      end
      self
    end

    # Swaps `col1` and `col2`
    def swap_columns(col1, col2)
      raise IndexError.new if col1 >= column_count || col2 >= column_count
      col1 += column_count if col1 < 0
      col2 += column_count if col2 < 0
      raise IndexError.new if col1 < 0 || col2 < 0
      row_count.times do |i|
        self[i, col1], self[i, col2] = self[i, col2], self[i, col1]
      end
      self
    end

    #--
    # TESTING -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
    #++

    # Returns `true` if this is a diagonal matrix.
    #
    def diagonal?
      return false unless square?
      els = [] of T
      each(:off_diagonal) { |e| els << e }
      els.all?(&.zero?)
    end

    # Returns true if this matrix is empty.
    def empty?
      column_count == 0 || row_count == 0
    end

    # Returns `true` if this is an hermitian matrix.
    def hermitian?
      return false unless square?
      els = [] of Tuple(T, Int32, Int32)
      each_with_index(:upper) { |e, i, j| els << {e, i, j} }
      els.all? do |e, row, col|
        e == rows[col][row]
      end
    end

    # Returns true if this matrix is a lower triangular matrix.
    def lower_triangular?
      els = [] of T
      each(:strict_upper) { |e| els << e }
      els.all?(&.zero?)
    end

    # Returns `true` if this is a normal matrix.
    #
    # ```
    # Matrix[[1, 1, 0], [0, 1, 1], [1, 0, 1]].normal?
    # # => true
    # ```
    def normal?
      return false unless square?
      rows.each_with_index do |row_i, i|
        rows.each_with_index do |row_j, j|
          s = 0
          rows.each_with_index do |row_k, k|
            s += row_i[k] * row_j[k] - row_k[i] * row_k[j]
          end
          return false unless s == 0
        end
      end
      true
    end

    # Returns `true` if this is an orthogonal matrix
    #
    # ```
    # Matrix[[1, 0], [0, 1]].orthogonal?
    # # => true
    # ```
    def orthogonal?
      return false unless square?
      rows.each_with_index do |row, i|
        column_count.times do |j|
          s = 0
          row_count.times do |k|
            s += row[k] * rows[k][j]
          end
          return false unless s == (i == j ? 1 : 0)
        end
      end
      true
    end

    # Returns `true` if this is a permutation matrix
    #
    # ```
    # Matrix[[1, 0], [0, 1]].permutation?
    # # => true
    # ```
    def permutation?
      return false unless square?
      cols = Array.new(column_count, false)
      rows.each_with_index do |row, i|
        found = false
        row.each_with_index do |e, j|
          if e == 1
            return false if found || cols[j]
            found = cols[j] = true
          elsif e != 0
            return false
          end
        end
        return false unless found
      end
      true
    end

    # Returns `true` if this matrix contains real numbers,
    # i.e. not `Complex`.
    #
    # ```
    # require "complex"
    # Matrix[[Complex.new(1, 0)], [Complex.new(0, 1)]].real?
    # # => false
    # ```
    def real?
      !(T.to_s == "Complex")
    end

    # Returns `true` if this is a regular (i.e. non-singular) matrix.
    def regular?
      !singular?
    end

    # Returns `true` if this is a singular matrix.
    def singular?
      determinant == 0
    end

    # Returns `true` if this is a square matrix.
    def square?
      column_count == row_count
    end

    # Returns +true+ if this is a symmetric matrix.
    # Raises an error if matrix is not square.
    #
    def symmetric?
      return false unless square?
      result = true
      each_with_index(:strict_upper) do |e, row, col|
        if e != rows[col][row]
          result = false
        end
      end
      result
    end

    # Returns `true` if this is a unitary matrix
    def unitary?
      return false unless square?
      result = true
      rows.each_with_index do |row, i|
        column_count.times do |j|
          s = 0

          row_count.times do |k|
            s += row[k] * rows[k][j]
          end

          unless s == (i == j ? 1 : 0)
            result = false
          end
        end
      end
      result
    end

    # Returns true if this matrix is a upper triangular matrix.
    def upper_triangular?
      els = [] of T
      each(:strict_lower) { |e| els << e }
      els.all?(&.zero?)
    end

    # Returns `true` if this is a matrix with only zero elements
    def zero?
      @rows.flatten.all?(&.zero?)
    end

    #--
    # OBJECT METHODS -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
    #++

    # Equality operator
    def ==(other : Matrix)
      rows == other.rows && column_count == other.column_count
    end

    # Returns a clone of the matrix, so that the contents of each do not reference
    # identical objects.
    #
    # There should be no good reason to do this since Matrices are immutable.
    def clone
      Matrix.new(@rows.map(&.dup), column_count)
    end

    #--
    # ARITHMETIC -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
    #++

    # Matrix multiplication
    #
    # ```
    # Matrix[[2,4], [6,8]] * Matrix.identity(2)
    # # => [ 2, 4,
    # #      6, 8 ]
    # ```
    def *(other)
      case other
      when Number
        rows = @rows.map do |row|
          row.map { |e| (e * other).as(T) }
        end
        Matrix.new(rows, column_count)
      when Vector
        m = Matrix.column_vector(other)
        r = self * m
        r.column(0)
      when Matrix
          raise ErrDimensionMismatch.new if column_count != other.column_count
          rows = Array.new(row_count) do |i|
            Array.new(column_count) do |j|
              (0...column_count).reduce(0) do |vij, k|
                vij + self[i, k] * other[k, j]
              end
            end
          end
          Matrix.new(rows, column_count)
      else
        self * Matrix.rows(other)
      end
    end

    # Matrix addition
    #
    # ```
    # Matrix.scalar(2,5) + Matrix[[1,0], [-4,7]]
    # # => [ 6,  0,
    # #     -4,  1 ]
    # ```
    def +(other : Matrix | Indexable)
      case other
      when Vector
        other = Matrix.column_vector(other)
      when Matrix
      else
        other = Matrix.rows(other)
      end

      raise ErrDimensionMismatch.new unless row_count == other.row_count && column_count == other.column_count

      rows = Array.new(row_count) do |i|
        Array.new(column_count) do |j|
          (self[i, j] + other[i, j]).as(T)
        end
      end

      Matrix.new(rows, column_count)
    end

    # Matrix subtraction
    #
    # ```
    # Matrix[[1,5], [4,2]] - Matrix[[9,3], [-4,1]]
    # # => [-8, 2,
    # #      8, 1 ]
    # ```
    def -(other : Matrix | Indexable)
      case other
      when Vector
        other = Matrix.column_vector(other)
      when Matrix
      else
        other = Matrix.rows(other)
      end

      raise ErrDimensionMismatch.new unless row_count == other.row_count && column_count == other.column_count

      rows = Array.new(row_count) do |i|
        Array.new(column_count) do |j|
          (self[i, j] - other[i, j]).as(T)
        end
      end

      Matrix.new(rows, column_count)
    end

    # Matrix division (multiplication by the inverse).
    #
    # ```
    # Matrix[[7,6], [3,9]] / Matrix[[2,9], [3,1]]
    # # => [ -7,  1,
    # #      -3, -6 ]
    # ```
    def /(other)
      case other
      when Number
        rows = @rows.map do |row|
          row.map {|e| (e / other).as(T) }
        end
        return Matrix.new(rows, column_count)
      when Matrix
        return self * other.inverse
      else
        self / Matrix.rows(other)
      end
    end

    # Hadamard product
    #
    # ```
    # Matrix[[1,2], [3,4]].hadamard_product Matrix[[1,2], [3,2]]
    # # => [ 1,  4,
    # #      9,  8 ]
    # ```
    def hadamard_product(m)
      combine(m){ |a, b| a * b }
    end

    # Returns the inverse of the matrix.
    #
    # NOTE: Always returns a `Float64` regardless of `T`s type. To coerce
    # back into an `Int`, use `#coerce`.
    #
    # ```
    # Matrix[[-1, -1], [0, -1]].inverse
    # # => [ -1.0,  1.0,
    # #       0.0, -1.0 ]
    # ```
    def inverse
      raise ErrDimensionMismatch.new unless square?
      last = row_count - 1
      a = self.coerce(Float64)
      m = Matrix(Float64).identity(row_count)

      0.upto(last) do |k|
        i = k
        akk = a[k, k].abs
        (k + 1).upto(last) do |j|
          v = a[j, k].abs
          if v > akk
            i = j
            akk = v
          end
        end
        raise ErrNotRegular.new if akk == 0
        if i != k
          a.swap_rows(i, k)
          m.swap_rows(i, k)
        end
        akk = a[k, k]
        0.upto(last) do |ii|
          next if ii == k
          q = a[ii, k] / akk
          a[ii, k] = 0.0
          (k + 1).upto(last) do |j|
            a[ii, j] -= a[k, j] * q
          end
          0.upto(last) { |j| m[ii, j] -= m[k, j] * q }
        end
        (k + 1).upto(last) { |j| a[k, j] = a[k, j] / akk }
        0.upto(last) { |j| m[k, j] = m[k, j] / akk }
      end

      m
    end

    # Matrix exponentiation.
    #
    # Equivalent to multiplying the matrix by itself N times.
    # Non integer exponents will be handled by diagonalizing the matrix.
    #
    # ```
    # Matrix[[7,6], [3,9]] ** 2
    # # => [ 67, 96,
    # #      48, 99 ]
    # ```
    def **(other)
      # TODO
    end

    #--
    # MATRIX FUNCTIONS -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
    #++

    # Returns the determinant of the matrix.
    #
    # Beware that using Float values can yield erroneous results
    # because of their lack of precision.
    # Consider using exact types like Rational or BigDecimal instead.
    #
    # ```
    # Matrix[[7,6], [3,9]].determinant
    # # => 45
    # ```
    def determinant
      raise ErrDimensionMismatch.new unless square?
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

    # Returns the determinant of the matrix, using Bareiss' multistep
    # integer-preserving gaussian elimination. It has the same
    # computational cost order O(n^3) as standard Gaussian elimination.
    # Intermediate results are fraction free and of lower complexity.
    # A matrix of Integers will have thus intermediate results that are also Integers,
    # with smaller bignums (if any), while a matrix of Float will usually have
    # intermediate results with better precision.
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

    # Returns a new matrix resulting by stacking horizontally
    # the receiver with the given matrices
    #
    # ```
    # x = Matrix[[1, 2], [3, 4]]
    # y = Matrix[[5, 6], [7, 8]]
    # x.hstack(y) # => Matrix[[1, 2, 5, 6], [3, 4, 7, 8]]
    # ```
    def hstack(*matrices)
      self.class.hstack(self, *matrices)
    end

    # Returns the rank of the matrix.
    #
    # Beware that using Float values can yield erroneous results
    # because of their lack of precision.
    # Consider using exact types like Rational or BigDecimal instead.
    #
    # ```
    # Matrix[[7,6], [3,9]].rank
    # # => 2
    # ```
    def rank
      # We currently use Bareiss' multistep integer-preserving gaussian elimination
      # (see comments on determinant)
      a = to_a
      last_column = column_count - 1
      last_row = row_count - 1
      pivot_row = 0
      previous_pivot = 1
      0.upto(last_column) do |k|
        switch_row = (pivot_row .. last_row).find {|row|
          a[row][k] != 0
        }
        if switch_row
          a[switch_row], a[pivot_row] = a[pivot_row], a[switch_row] unless pivot_row == switch_row
          pivot = a[pivot_row][k]
          (pivot_row+1).upto(last_row) do |i|
            ai = a[i]
            (k+1).upto(last_column) do |j|
              ai[j] =  (pivot * ai[j] - ai[k] * a[pivot_row][j]) / previous_pivot
            end
          end
          pivot_row += 1
          previous_pivot = pivot
        end
      end
      pivot_row
    end

    # Returns a matrix with entries rounded to the given precision
    # (see `Float#round`)
    def round(n = 0)
      map {|e| e.round(n) }
    end

    # Returns the trace (sum of diagonal elements) of the matrix.
    #
    # ```
    # Matrix[[7,6], [3,9]].trace
    # # => 16
    # ```
    def trace
      raise ErrDimensionMismatch.new unless square?
      (0...column_count).reduce(0) do |tr, i|
        tr + @rows[i][i]
      end
    end

    # ditto
    def tr
      trace
    end

    # Returns the transpose of the matrix.
    #
    # ```
    # Matrix[[1,2], [3,4], [5,6]]
    # # => [ 1, 2,
    # #      3, 4,
    # #      5, 6 ]
    # Matrix[[1,2], [3,4], [5,6]].transpose
    # # => [ 1, 3, 5,
    # #      2, 4, 6 ]
    # ```
    def transpose
      return self.class.empty(column_count, 0) if row_count.zero?
      Matrix.new(@rows.transpose, row_count)
    end

    # ditto
    def t
      transpose
    end

    # Returns a new matrix resulting by stacking vertically
    # the receiver with the given matrices
    #
    # ```
    # x = Matrix[[1, 2], [3, 4]]
    # y = Matrix[[5, 6], [7, 8]]
    # x.vstack(y)
    # # => Matrix[[1, 2], [3, 4], [5, 6], [7, 8]]
    # ```
    def vstack(*matrices)
      self.class.vstack(self, *matrices)
    end

    #--
    # DECOMPOSITIONS -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
    #++

    # Returns the Eigensystem of the matrix
    # See `EigenvalueDecomposition`.
    #
    # NOTE: Not working yet
    #
    # ```
    # m = Matrix[[1, 2], [3, 4]]
    # v, d, v_inv = m.eigensystem
    # d.diagonal? # => true
    # v.inv == v_inv # => true
    # (v * d * v_inv).round(5) == m # => true
    # ```
    def eigensystem
      EigenvalueDecomposition.new(self)
    end

    # Returns the LUP decomposition of the matrix
    # See +LUPDecomposition+.
    #
    # NOTE: Not working yet
    #
    # ```
    # a = Matrix[[1, 2], [3, 4]]
    # l, u, p = a.lup
    # l.lower_triangular? # => true
    # u.upper_triangular? # => true
    # p.permutation?      # => true
    # l * u == p * a      # => true
    # a.lup.solve([2, 5]) # => Vector[(1/1), (1/2)]
    # ```
    def lup
      LUPDecomposition.new(self)
    end

    #--
    # COMPLEX ARITHMETIC -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
    #++

    # Returns the conjugate of the matrix.
    #
    # ```
    # Matrix[[Complex(1,2), Complex(0,1), 0], [1, 2, 3]]
    # # => 1+2i   i  0
    # #       1   2  3
    # Matrix[[Complex(1,2), Complex(0,1), 0], [1, 2, 3]].conj
    # # => 1-2i  -i  0
    # #       1   2  3
    # ```
    def conj
      raise ArgumentError.new("Matrix#conj only works with real matrices (i.e. Matrix(Complex))") unless real?
      map(&.conj)
    end

    # Returns the imaginary part of the matrix.
    #
    # ```
    # Matrix[[Complex(1,2), Complex(0,1), 0], [1, 2, 3]]
    # # => [ 1+2i,  i,  0,
    # #         1,  2,  3 ]
    # Matrix[[Complex(1,2), Complex(0,1), 0], [1, 2, 3]].imag
    # # => [ 2i,  i,  0,
    # #       0,  0,  0 ]
    # ```
    def imag
      raise ArgumentError.new("Matrix#imag only works with real matrices (i.e. Matrix(Complex))") unless real?
      map(&.imag)
    end

    # Returns the real part of the matrix.
    #
    # ```
    # Matrix[[Complex(1,2), Complex(0,1), 0], [1, 2, 3]]
    # # => [ 1+2i,  i,  0,
    # #         1,  2,  3 ]
    # Matrix[[Complex(1,2), Complex(0,1), 0], [1, 2, 3]].real
    # # => [ 1,  0,  0,
    # #      1,  2,  3 ]
    # ```
    def real
      raise ArgumentError.new("Matrix#real only works with real matrices (i.e. Matrix(Complex))") unless real?
      map(&.real)
    end

    # Returns an array containing matrices corresponding to the real and imaginary
    # parts of the matrix
    #
    # ```
    # m.rect == [m.real, m.imag]
    # # ==> true for all matrices m
    # ```
    def rect
      raise ArgumentError.new("Matrix#real only works with real matrices (i.e. Matrix(Complex))") unless real?
      [real, imag]
    end

    #--
    # CONVERTING -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
    #++

    # Attempt to coerce the elements in the matrix to another type.
    def coerce(klass)
      rws = @rows.map { |r| r.map { |i| klass.new(i) } }
      Matrix.rows(rws)
    end

    def to_s(io)
      if empty?
        "Matrix.empty(#{row_count}, #{column_count})"
      else
        io << "Matrix["

        io << rows.map { |row|
          "[" + row.map { |e| e.to_s }.join(", ") + "]"
        }.join(", ")

        io << "]"
      end
    end

    def pretty_print(pp) : Nil
      pp.group(1, "[", "]") do
        self.rows.each_with_index do |elem, i|
          pp.comma if i > 0
          elem.pretty_print(pp)
        end
      end
    end

    def to_json(json : JSON::Builder)
      json.array do
        each &.to_json(json)
      end
    end

    # Returns this matrix as an `Array(Array(T))`
    def to_a
      @rows.clone
    end

    def unsafe_fetch(i)
      @rows.unsafe_fetch(i)
    end
  end
end
