module Apatite
  class Matrix(T)
    # Eigenvalues and eigenvectors of a real matrix.
    #
    # Computes the eigenvalues and eigenvectors of a matrix A.
    #
    # If A is diagonalizable, this provides matrices V and D
    # such that A = V*D*V.inv, where D is the diagonal matrix with entries
    # equal to the eigenvalues and V is formed by the eigenvectors.
    #
    # If A is symmetric, then V is orthogonal and thus A = V*D*V.t
    class EigenvalueDecomposition
      def initialize(matrix)
      end
    end
  end
end
