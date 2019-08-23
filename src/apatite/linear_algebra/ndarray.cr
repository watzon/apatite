module Apatite::LinearAlgebra
  class NDArray
    # include Enumerable(Float64)
    # include Indexable(Float64)
    # include Comparable(NDArray)

    # getter data : Array(Float64)

    # getter shape : Array(Int32)

    # delegate :[], to: @data
    # delegate :[]?, to: @data
    # delegate :[]=, to: @data
    # delegate :unsafe_fetch, to: @data
    # delegate :to_unsafe, to: @data
    # delegate :size, to: @data

    # def initialize(data : Array(Number), shape : Array(Int32)? = nil)
    #   @data = data.is_a?(Array(Float64)) ? data.flatten : data.flatten.map(&.to_f64)
    #   @shape = shape || [@data.size]
    # end

    # # Returns the absolute value of every item in the array
    # def abs
    #   map { |e| e.abs }
    # end

    # # Returns the arccosine of each element in the current array.
    # def acos
    # end
  end
end
