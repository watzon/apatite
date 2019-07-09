module Apatite
  module LinearAlgebra
    class Error < Exception; end
    class ErrDimensionMismatch < Error; end
    class ZeroVectorError < Error; end
    class ErrNotRegular < Error; end

    class ErrOperationNotDefined < Error
      def initialize(method, this, other)
        message = "no overload matches '#{this}##{method}' with type #{other}"
        super(message)
      end
    end
  end
end
