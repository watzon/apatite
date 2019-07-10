module Apatite::LinearAlgebra
  class Matrix(T)
    # For an m-by-n matrix A with m >= n, the LU decomposition is an m-by-n
    # unit lower triangular matrix L, an n-by-n upper triangular matrix U,
    # and a m-by-m permutation matrix P so that L*U = P*A.
    # If m < n, then L is m-by-m and U is m-by-n.
    #
    # The LUP decomposition with pivoting always exists, even if the matrix is
    # singular, so the constructor will never fail.  The primary use of the
    # LU decomposition is in the solution of square systems of simultaneous
    # linear equations.  This will fail if singular? returns true.
    class LupDecomposition
      def initialize(matrix)
      end
    end
  end
end
