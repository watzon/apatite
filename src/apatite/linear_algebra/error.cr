module Apatite
  module LinearAlgebra
    class Error < Exception; end
    class ErrDimensionMismatch < Error; end
    class ZeroVectorError < Error; end
    class ErrOperationNotDefined < Error; end
  end
end
