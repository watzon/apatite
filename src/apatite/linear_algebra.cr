require "./linear_algebra/error"
# require "./linear_algebra/ndarray"
require "./linear_algebra/matrix"
require "./linear_algebra/vector"

module Apatite
  module LinearAlgebra
    extend self

    # Calculates the sigmoid curve for a numeric input.
    #
    # `f(x) = 1/(1 + e^-x)`
    #
    # See also: [Sigmoid function (WikiWand)](https://www.wikiwand.com/en/Sigmoid_function)
    def sigmoid(input : Number)
      num = input.to_f64
      1 / (1 + Math.exp(-num))
    end

    # Calculates the derivative sigmoid curve for a numeric input.
    #
    # `f'(x) = f(x)(1 - f(x)),`
    def sigmoid_d(input : Number)
      num = input.to_f64
      num * (1 - num)
    end
  end
end
