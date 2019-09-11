module Apatite
  class Error < Exception; end
  class ErrDimensionMismatch < Error; end
  class ZeroVectorError < Error; end
  class ErrNotRegular < Error; end
  class ErrOperationNotDefined < Error; end
end
