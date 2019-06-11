class Array(T)
  # Tests whether all elements evaluate to true
  def all?
    each { |i| if !!i == false
      return false
    end }
    true
  end

  # Tests whether any of the elements evaluate to true
  def any?
    each { |i| if !!i == true
      return true
    end }
    false
  end

  # Get the array's dimensions
  def shape
    max = max_by { |i| i.is_a?(Array) ? i.size : i }
    max.is_a?(Array) ? [size, max.size] : [max]
  end

  def to_vec
    Apatite::Vector.create(self)
  end
end
