require "./apatite/core_ext/array"

require "./apatite/linear_algebra"

# Apatite is a fundimental package for scientific computing in Crystal. If that
# sounds like a modified version of the first line from the NumPy homepage,
# that's because it is. Apatite has (ok, will have) all of the goodness
# of NumPy sitting atop the blazing speed and beautiful syntax
# of Crystal.
module Apatite
  extend self
  include Apatite::LinearAlgebra

end
