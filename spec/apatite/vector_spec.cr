require "../spec_helper"

describe "Apatite::Vector" do
  x = Apatite::Vector.new([3, 4])

  describe "#==" do
    it "is true if elements are the same" do
      (x == Apatite::Vector.new([3, 4])).should be_true
    end

    it "is false if elements are different" do
      (x == Apatite::Vector.new([7, 1])).should be_false
    end
  end

  describe "#e" do
    it "returns the `ith` element in the vector" do
      x.e(2).should eq(4)
    end

    it "returns `nil` if `n` is out of range" do
      x.e(7).should be_nil
    end
  end

  describe "#to_unit_vector" do
    it "successfully converts a vector to a unit vector" do
      res = [0.6, 0.8]
      x.to_unit_vector.each_with_index do |e, i|
        e.should be_close(res[i], 0.1)
      end
    end
  end

  describe "#dimensions" do
    it "gets vector's dimensions" do
      x.dimensions.should eq({1, 2})
    end
  end

  describe "#rows" do
    it "gets vector's rows" do
      x.rows.should eq(1)
    end
  end

  describe "#cols" do
    it "gets vector's columns" do
      x.cols.should eq(2)
    end
  end

  describe "#product" do
    it "computes the product of a vector" do
      x.product.should eq(12)
    end
  end

  describe "#angle_from" do
    it "should compute the angle between `y` and `z`" do
      y = Apatite::Vector.create([1, 1])
      z = Apatite::Vector.create([1, 0])
      y.angle_from(z).should be_close(Math::PI / 4, 0.1)
    end
  end

  describe "#parallel_to?" do
    it "correctly determines if a vector is parallel to another" do
      x.parallel_to?(Apatite::Vector.create([6, 8])).should be_true
      x.parallel_to?(Apatite::Vector.create([1, 1])).should be_false
    end
  end

  describe "#antiparallel_to?" do
    it "correctly determines if a vector is antiparallel to another" do
      x.antiparallel_to?(Apatite::Vector.create([-3, -4])).should be_true
      x.antiparallel_to?(x).should be_false
    end
  end

  describe "#perpendicular_to?" do
    it "correctly determines if a vector is antiparallel to another" do
      x.perpendicular_to?(Apatite::Vector.create([-4, 3])).should be_true
      x.perpendicular_to?(x).should be_false
    end
  end

  describe "#dot" do
    it "calculates the dot product of the vector and another vector" do
      x.dot(Apatite::Vector.create([2, 3])).should eq(18)
    end
  end

  describe "#add" do
    it "adds a number to every item in a vector" do
      x.add(2).should eq([5, 6])
    end

    it "adds an enumerable to a vector" do
      x.add([3, 2]).should eq([6, 6])
    end
  end

  describe "#subtract" do
    it "subtracts a number from every item in a vector" do
      x.subtract(2).should eq([1, 2])
    end

    it "subtracts an enumerable from a vector" do
      x.subtract([3, 2]).should eq([0, 2])
    end
  end

  describe "#multiply" do
    it "multiplies a number with every item in a vector" do
      x.multiply(2).should eq([6, 8])
    end

    it "multiplies an enumerable with a vector" do
      x.multiply([3, 2]).should eq([9, 8])
    end
  end

  describe "#sum" do
    it "sums all items in a vector" do
      x.sum.should eq(7)
    end
  end

  describe "#chomp" do
    it "returns a new vector with the first `n` items of the old vector" do
      x.chomp(1).should eq([4])
    end
  end

  describe "#top" do
    it "returns a new vector with the last `n` items of the old vector" do
      x.top(1).should eq([3])
    end
  end

  describe "#augment" do
    it "creates a new vector with the elements fro vector b appended to those from vector a" do
      y = x.clone
      y.augment(Apatite::Vector.create([5])).should eq([3, 4, 5])
    end
  end

  describe ".log" do
    it "should calculate the log of the vector" do
      pp x
      x.log.should eq([1.0986122886681098, 1.3862943611198906])
    end
  end

  it "should allow for scalar addition" do
    a = Apatite::Vector.create([2, 3, 4])
    b = a.add(1)
    b.should eq([3, 4, 5])
  end
end
