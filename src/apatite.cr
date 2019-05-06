require "./apatite/core_ext/*"
require "./apatite/narray"

# Apatite is a fundimental package for scientific computing in Crystal. If that
# sounds like a modified version of the first line from the NumPy homepage,
# that's because it is. Apatite has (ok, will have) all of the goodness
# of NumPy sitting atop the blazing speed and beautiful syntax
# of Crystal.
module Apatite
  VERSION = "0.1.0"

  # def self.zeros(shape : Array(Int32))
  #   curr = shape.shift
  #   Array.new(curr) do
  #     if shape.empty?
  #       Array.new(curr, 0)
  #     else
  #       self.zeros(shape)
  #     end
  #   end
  # end

  ## ## ## ## ## ## ## ## ## ## ## ## ##
  # # Array Creation
  ## ## ## ## ## ## ## ## ## ## ## ## ##

  def self.empty
  end

  def self.empty_like
  end

  def self.eye
  end

  def self.itentity
  end

  def self.ones
  end

  def self.ones_like
  end

  def self.zeros
  end

  def self.zeros_like
  end

  def self.full
  end

  def self.full_like
  end

  def self.array
  end

  def self.as_array
  end

  def self.asanyarray
  end

  def self.ascontiguousarray
  end

  def self.asmatrix
  end

  def self.copy
  end

  def self.from_buffer
  end

  def self.from_function
  end

  def self.from_iter
  end

  def self.from_string
  end

  def self.arrange
  end

  def self.linspace
  end

  def self.logspace
  end

  def self.geomspace
  end

  def self.meshgrid
  end

  def self.mgrid
  end

  def self.ogrid
  end

  def self.diag
  end

  def self.diagflat
  end

  def self.tri
  end

  def self.tril
  end

  def self.triu
  end

  def self.vander
  end

  def self.mat
  end

  def self.bmat
  end

  ## ## ## ## ## ## ## ## ## ## ## ## ##
  # # Array Manipulation
  ## ## ## ## ## ## ## ## ## ## ## ## ##

  def self.copyto
  end

  def self.reshape
  end

  def self.ravel
  end

  def self.moveaxis
  end

  def self.rollaxis
  end

  def self.swapaxes
  end

  def self.transpose
  end

  def self.atleast_1d
  end

  def self.atleast_2d
  end

  def self.atleast_3d
  end

  def self.broadcast
  end

  def self.broadcast_to
  end

  def self.broadcast_arrays
  end

  def self.expand_dims
  end

  def self.squeeze
  end

  def self.as_array
  end

  def self.as_any_array
  end

  def self.as_matrix
  end

  def self.as_f_array
  end

  def self.as_fortran_array
  end

  def self.as_contiguous_array
  end

  def self.as_array_chkfinite
  end

  def self.as_scalar
  end

  def self.require
  end

  def self.concat
  end

  def self.stack
  end

  def self.column_stack
  end

  def self.dstack
  end

  def self.hstack
  end

  def self.vstack
  end

  def self.block
  end

  def self.split
  end

  def self.array_split
  end

  def self.dsplit
  end

  def self.hsplit
  end

  def self.vsplit
  end

  def self.tile
  end

  def self.repeat
  end

  def self.delete
  end

  def self.insert
  end

  def self.append
  end

  def self.resize
  end

  def self.trim_zeros
  end

  def self.unique
  end

  def self.flip
  end

  def self.fliplr
  end

  def self.flipud
  end

  def self.reshape
  end

  def self.roll
  end

  def self.rot90
  end

  ## ## ## ## ## ## ## ## ## ## ## ## ##
  # # Binary Operations
  ## ## ## ## ## ## ## ## ## ## ## ## ##

  def self.bitwise_and
  end

  def self.bitwise_or
  end

  def self.bitwise_xor
  end

  def self.invert
  end

  def self.left_shift
  end

  def self.right_shift
  end

  def self.pack_bits
  end

  def self.unpack_bits
  end

  def self.binary_repr
  end

  ## ## ## ## ## ## ## ## ## ## ## ## ##
  # # String Operations
  ## ## ## ## ## ## ## ## ## ## ## ## ##

  module String
    def self.add
    end

    def self.multiply
    end

    def self.mod
    end

    def self.capitalize
    end

    def self.center
    end

    def self.decode
    end

    def self.encode
    end

    def self.join
    end

    def self.ljust
    end

    def self.lower
    end

    def self.lstrip
    end

    def self.partition
    end

    def self.replace
    end

    def self.rjust
    end

    def self.rpartition
    end

    def self.rsplit
    end

    def self.rstrip
    end

    def self.split
    end

    def self.split_lines
    end

    def self.strip
    end

    def self.swap_case
    end

    def self.title
    end

    def self.translate
    end

    def self.upper
    end

    def self.zfill
    end

    def self.equal?
    end

    def self.not_equal?
    end

    def self.greater_equal?
    end

    def self.less_equal?
    end

    def self.greater?
    end

    def self.less?
    end

    def self.count
    end

    def self.find
    end

    def self.index
    end

    def self.alpha?
    end

    def self.decimal?
    end

    def self.digit?
    end

    def self.lower?
    end

    def self.numeric?
    end

    def self.space?
    end

    def self.title?
    end

    def self.upper?
    end

    def self.rfind
    end

    def self.rindex
    end

    def self.starts_with?
    end
  end

  ## ## ## ## ## ## ## ## ## ## ## ## ##
  # # Financial Functions
  ## ## ## ## ## ## ## ## ## ## ## ## ##

  module Financial
    # Calculates the [future value](http://financeformulas.net/Future_Value.html)
    # for a given present value, rate of return, and number of periods.
    #
    # So for example, say we have an individual that would like to determine
    # their ending balance after one year for an account that earns .5%
    # interest per month and is compounded monthly. The original balance
    # on the account is $1000. We would calculate their FV in the
    # following way:
    #
    # ```
    # puts Apatite::Financial.fv(1000, 0.005, 12)
    # # => 1061.68
    # ```
    #
    # The 1000 is the $1000 present value, the 0.005 is the .5% rate of return,
    # and the 12 is for 12 monthly periods.
    def self.fv(pv, rate, nper)
      ans = pv * (1 + rate) ** nper
      ans.round(2)
    end

    # Calculates the [present value]()
    # for a given future value, rate of return, and number of periods.
    #
    # So for example, say we have an individual who wishes to determine how
    # much money she would need to put into her money market account to
    # have $100 one year today if she is earning 5% interest on her
    # account, simple interest. We would calculate her PV like this:
    #
    # ```
    # puts Apatite::Financial.pv(100, 0.005, 12)
    # => 95.24
    # ```
    #
    # The 100 is for the amount she wishes to have at the end of the 12
    # months, the 0.005 is for the .5% rate of return, and the 12 is
    # for the 12 months.
    def self.pv(fv, rate, nper)
      ans = fv * (1 / (1 + rate) ** nper)
      ans.round(2)
    end

    def self.npv
    end

    def self.pmt
    end

    def self.ppmt
    end

    def self.lpmt
    end

    def self.irr
    end

    def self.mirr
    end

    def self.nper
    end

    def self.rate
    end
  end

  ## ## ## ## ## ## ## ## ## ## ## ## ##
  # # Logic Functions
  ## ## ## ## ## ## ## ## ## ## ## ## ##

  def self.all?(arr : Enumerable)
  end

  def self.any?
  end

  def self.finite?
  end

  def self.infinite?
  end

  def self.nan?
  end

  def self.nat?
  end

  def self.complex?
  end

  def self.complex_object?
  end

  def self.fortran?
  end

  def self.real?
  end

  def self.real_object?
  end

  def self.scalar?
  end

  def self.all_close?
  end

  def self.close?
  end

  def self.arr_equal?
  end

  def self.arr_equiv?
  end

  def self.greater?
  end

  def self.greater_equal?
  end

  def self.less?
  end

  def self.less_equal?
  end

  def self.equal?
  end

  def self.equal?
  end

  def self.not_equal?
  end

  ## ## ## ## ## ## ## ## ## ## ## ## ##
  # # Mathematical Functions
  ## ## ## ## ## ## ## ## ## ## ## ## ##

  def self.sin
  end

  def self.cos
  end

  def self.tan
  end

  def self.arcsin
  end

  def self.arccos
  end

  def self.arctan
  end

  def self.hypot
  end

  def self.arctan2
  end

  def self.degrees
  end

  def self.radians
  end

  def self.unwrap
  end

  def self.deg2rad
  end

  def self.rad2deg
  end

  def self.sinh
  end

  def self.cosh
  end

  def self.tanh
  end

  def self.arcsinh
  end

  def self.arccosh
  end

  def self.arctanh
  end

  def self.around
  end

  def self.round
  end

  def self.rint
  end

  def self.fix
  end

  def self.floor
  end

  def self.cell
  end

  def self.trunc
  end

  def self.prod
  end

  def self.sum
  end

  def self.nanprod
  end

  def self.nansum
  end

  def self.cumprod
  end

  def self.cumsum
  end

  def self.nancumprod
  end

  def self.nancumsum
  end

  def self.diff
  end

  def self.ediff1d
  end

  def self.gradient
  end

  def self.cross
  end

  def self.trapz
  end

  def self.exp
  end

  def self.expm1
  end

  def self.exp2
  end

  def self.log
  end

  def self.log10
  end

  def self.log2
  end

  def self.log1p
  end

  def self.logaddexp
  end

  def self.logaddexp2
  end

  def self.i0
  end

  def self.sinc
  end

  def self.sign_bit
  end

  def self.copy_sign
  end

  def self.frexp
  end

  def self.ldexp
  end

  def self.next_after
  end

  def self.spacing
  end

  def self.lcm
  end

  def self.gcd
  end

  def self.add
  end

  def self.reciprocal
  end

  def self.positive
  end

  def self.negative
  end

  def self.multiply
  end

  def self.divide
  end

  def self.power
  end

  def self.subtract
  end

  def self.true_divide
  end

  def self.floor_divide
  end

  def self.float_power
  end

  def self.fmod
  end

  def self.mod
  end

  def self.modf
  end

  def self.remainder
  end

  def self.divmod
  end

  def self.angle
  end

  def self.real
  end

  def self.imag
  end

  def self.conj
  end

  def self.convolve
  end

  def self.clip
  end

  def self.sqrt
  end

  def self.cbrt
  end

  def self.square
  end

  def self.absolute
  end

  def self.fabs
  end

  def self.sign
  end

  def self.heaviside
  end

  def self.maximum
  end

  def self.minimum
  end

  def self.fmax
  end

  def self.fmin
  end

  def self.nan_to_num
  end

  def self.real_if_close
  end

  def self.interp
  end

  ## ## ## ## ## ## ## ## ## ## ## ## ##
  # # Padding Arrays
  ## ## ## ## ## ## ## ## ## ## ## ## ##

  def self.pad
  end

  ## ## ## ## ## ## ## ## ## ## ## ## ##
  # # Polynomials
  ## ## ## ## ## ## ## ## ## ## ## ## ##

  module Polynomial
    def self.polyval
    end

    def self.polyval2d
    end

    def self.polyval3d
    end

    def self.polygrid2d
    end

    def self.polygrid3d
    end

    def self.polyroots
    end

    def self.polyfromroots
    end

    def self.polyvalfromroots
    end

    def self.polyfit
    end

    def self.polyvander
    end

    def self.polyvander2d
    end

    def self.polyvander3d
    end

    def self.polyder
    end

    def self.polyint
    end

    def self.polyadd
    end

    def self.polysub
    end

    def self.polymul
    end

    def self.polymulx
    end

    def self.polydiv
    end

    def self.polypow
    end

    def self.polycompanion
    end

    def self.polydomain
    end

    def self.polyzero
    end

    def self.polyone
    end

    def self.polyx
    end

    def self.polytrim
    end

    def self.polyline
    end
  end

  ## ## ## ## ## ## ## ## ## ## ## ## ##
  # # Sorting, Searching, and Counting
  ## ## ## ## ## ## ## ## ## ## ## ## ##

  def self.sort
  end

  def self.lexsort
  end

  def self.argsort
  end

  def self.msort
  end

  def self.sort_complex
  end

  def self.partition
  end

  def self.argpartition
  end

  def self.argmax
  end

  def self.nanargmax
  end

  def self.argmin
  end

  def self.nanargmin
  end

  def self.argwhere
  end

  def self.nonzero
  end

  def self.flatnonzero
  end

  def self.where
  end

  def self.searchsorted
  end

  def self.extract
  end

  def self.count_nonzero
  end

  ## ## ## ## ## ## ## ## ## ## ## ## ##
  # # Statistics
  ## ## ## ## ## ## ## ## ## ## ## ## ##

  def self.amin
  end

  def self.amax
  end

  def self.nanmin
  end

  def self.nanmax
  end

  def self.ptp
  end

  def self.percentile
  end

  def self.nanpercentile
  end

  def self.quantile
  end

  def self.nanquantile
  end

  def self.median
  end

  def self.average
  end

  def self.mean
  end

  def self.std
  end

  def self.var
  end

  def self.nanmedian
  end

  def self.nanmean
  end

  def self.nanstd
  end

  def self.nanvar
  end

  def self.corrcoef
  end

  def self.correlate
  end

  def self.cov
  end

  def self.histogram
  end

  def self.histogram2d
  end

  def self.histogramdd
  end

  def self.bincount
  end

  def self.histogram_bin_edges
  end

  def self.digitize
  end
end
