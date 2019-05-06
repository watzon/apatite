module Apatite
  class NArray(T) < Array(T)
    include Indexable(T)
    include Comparable(NArray)

    getter size : Int32
    getter shape : Array(Int32)
    getter ndim : Int32

    def initialize(@selection : T, @dtype = Int32)
      @size = @selection.size
      @shape = @selection.shape
      @ndim = @shape.size
      super(1, @selection)
    end

    # def self.new(shape : Array(Int32), &block : Int32 -> T)
    # end

    # def ==(other : NArray)
    # end

    # # :nodoc:
    # def ==(other)
    #   false
    # end

    # def <=>(other : NArray)
    # end

    # def &(other : NArray(U)) forall U
    # end

    # def |(other : NArray(U)) forall U
    # end

    # def +(other : NArray(U)) forall U
    # end

    # def -(other : NArray(U)) forall U
    # end

    # def *(times : Int)
    # end

    # def <<(value : T)
    # end

    # @[AlwaysInline]
    # def []=(index : Int, value : T)
    # end

    # def []=(index : Int, count : Int, value : T)
    # end

    # def []=(range : Range(Int, Int), value : T)
    # end

    # def []=(index : Int, count : Int, values : NArray(T))
    # end

    # def []=(range : Range(Int, Int), values : NArray(T))
    # end

    # def [](range : Range(Int, Int))
    # end

    # def [](start : Int, count : Int)
    # end

    def all?
      flatten.all?
    end

    def any?
      flatten.any?
    end

    # def arg_max
    # end

    # def arg_min
    # end

    # def arg_partition
    # end

    # def arg_sort
    # end

    # def as_type
    # end

    # def byte_swap(inplace = false)
    # end

    # def choose
    # end

    # def clip
    # end

    # def compress
    # end

    # def conj
    # end

    # def conjugate
    # end

    # def copy
    # end

    # def cum_prod
    # end

    # def cum_sum
    # end

    # def diagonal
    # end

    # def dot
    # end

    # def dump
    # end

    # def dumps
    # end

    # def fill
    # end

    # def flatten
    # end

    # def get_field
    # end

    # def item
    # end

    # def item_set
    # end

    # def max
    # end

    # def mean
    # end

    # def min
    # end

    # def new_byte_order
    # end

    # def non_zero
    # end

    # def partition
    # end

    # def prod
    # end

    # def ptp
    # end

    # def put
    # end

    # def ravel
    # end

    # def repeat
    # end

    # def repeat
    # end

    # def reshape
    # end

    # def resize
    # end

    # def round
    # end

    # def search_sorted
    # end

    # def set_field
    # end

    # def set_flags
    # end

    # def sort
    # end

    # def squeeze
    # end

    # def std
    # end

    # def sum
    # end

    # def swap_axes
    # end

    # def take
    # end

    # def to_bytes
    # end

    # def to_a
    # end

    # def to_json
    # end

    # def to_s
    # end

    # def to_unsafe
    # end

    # def to_yaml
    # end

    # def trace
    # end

    # def transpose
    # end

    # @[AlwaysInline]
    # def unsafe_fetch(index : Int)
    #   @buffer[index]
    # end

    # def var
    # end

    # def view
    # end
  end
end
