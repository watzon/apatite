require "../spec_helper"

describe "Apatite::Vector" do
  describe ".[]" do
    it "creates a new vector from a list of elements" do
      vec = Apatite::Vector[1, 2, 3]
      vec.should be_a Apatite::Vector(Int32)
      vec[0].should eq 1
      vec[2].should eq 3
    end
  end

  describe ".elements" do
    it "creates a new vector from an Array" do
      arr = [1, 2, 3]
      vec = Apatite::Vector.elements(arr)
      vec.should be_a Apatite::Vector(Int32)
      vec[0].should eq 1
      vec[2].should eq 3
    end
  end

  describe ".basis" do
    it "creates a standard basis-n vector" do
      vec = Apatite::Vector.basis(5, 1)
      vec.should eq Apatite::Vector[0, 1, 0, 0, 0]

      vec = Apatite::Vector.basis(3, 2)
      vec.should eq Apatite::Vector[0, 0, 1]
    end
  end

  describe ".independent?" do
    it "returns true if all of vectors are linearly independent" do
      Apatite::Vector.independent?(Apatite::Vector[1,0], Apatite::Vector[0,1]).should be_true
      Apatite::Vector.independent?(Apatite::Vector[1,2], Apatite::Vector[2,4]).should be_false
    end
  end

  describe ".zero" do
    it "creates a new zero vector" do
      vec = Apatite::Vector(Int32).zero(5)
      vec.should eq Apatite::Vector[0, 0, 0, 0, 0]
    end
  end

  describe "#==" do
    it "is true if elements are the same" do
      x = Apatite::Vector.elements([3, 4])
      (x == Apatite::Vector.elements([3, 4])).should be_true
    end

    it "is false if elements are different" do
      x = Apatite::Vector.elements([3, 4])
      (x == Apatite::Vector.elements([7, 1])).should be_false
    end
  end

  describe "#+" do
    it "adds a number to every item in the vector" do
      vec = Apatite::Vector[1, 2, 3]
      vec2 = vec + 2
      vec2.should eq Apatite::Vector[3, 4, 5]
    end

    it "adds the items in one vector to each parallel item in another" do
      vec1 = Apatite::Vector[1, 2, 3]
      vec2 = Apatite::Vector[3, 2, 1]
      vec3 = vec1 + vec2

      vec3.should be_a Apatite::Vector(Int32)
      vec3.should eq Apatite::Vector[4, 4, 4]
    end

    pending "adds a vector to a matrix"
  end

  describe "#-" do
    it "subtracts a number from every item in the vector" do
      vec = Apatite::Vector[3, 4, 5]
      vec2 = vec - 2
      vec2.should eq Apatite::Vector[1, 2, 3]
    end

    it "subtracts the items in one vector from each parallel item in another" do
      vec1 = Apatite::Vector[1, 2, 3]
      vec2 = Apatite::Vector[3, 2, 1]
      vec3 = vec1 - vec2

      vec3.should be_a Apatite::Vector(Int32)
      vec3.should eq Apatite::Vector[-2, 0, 2]
    end

    pending "subtracts a vector from a matrix"
  end

  describe "#*" do
    it "multiplies every item in the vector by a number" do
      vec = Apatite::Vector[2, 3, 4]
      vec2 = vec * 2
      vec2.should eq Apatite::Vector[4, 6, 8]
    end

    it "multiplies the items in one vector with each parallel item in another" do
      vec1 = Apatite::Vector[1, 2, 3]
      vec2 = Apatite::Vector[3, 2, 1]
      vec3 = vec1 * vec2

      vec3.should be_a Apatite::Vector(Int32)
      vec3.should eq Apatite::Vector[3, 4, 3]
    end

    pending "multiplies a vector with a matrix"
  end

  describe "#/" do
    it "divides every item in the vector by a number" do
      vec = Apatite::Vector[2.0, 3.0, 4.0]
      vec2 = vec / 2
      vec2.should eq Apatite::Vector[1.0, 1.5, 2.0]
    end

    it "divides the items in one vector by each parallel item in another" do
      vec1 = Apatite::Vector[1.0, 2.0, 3.0]
      vec2 = Apatite::Vector[3.0, 2.0, 1.0]
      vec3 = vec1 / vec2

      vec3.should be_a Apatite::Vector(Float64)
      vec3.should eq Apatite::Vector[0.3333333333333333, 1.0, 3.0]
    end

    pending "divides a vector by a matrix"
  end

  describe "#==" do
    it "ensures two vectors are equal" do
      vec1 = Apatite::Vector[1, 2, 3]
      vec2 = Apatite::Vector[1, 2, 3]
      (vec1 == vec2).should be_true
    end

    it "checks equality between a vector and an array" do
      vec = Apatite::Vector[1, 2, 3]
      arr = [1, 2, 3]
      (vec == arr).should be_true
    end
  end

  describe "#angle_with" do
    it "returns an angle with another vector" do
      vec1 = Apatite::Vector[1, 2, 3]
      vec2 = Apatite::Vector[3, 2, 1]
      vec1.angle_with(vec2).should eq 0.7751933733103613
    end
  end

  describe "#clone" do
    it "creates a copy of the vector" do
      vec = Apatite::Vector[1, 2, 3]
      cpy = vec.clone
      vec.should eq cpy
      vec.object_id.should_not eq cpy.object_id
    end
  end

  describe "#map" do
    it "should map over a vector's elements" do
      vec1 = Apatite::Vector[1, 2, 3]
      vec2 = vec1.map(&.succ)
      vec2.should eq Apatite::Vector[2, 3, 4]
    end

    it "should map over two vectors simultaniously" do
      vec1 = Apatite::Vector[1, 2, 3]
      vec2 = Apatite::Vector[4, 5, 6]
      vec3 = vec1.map(vec2) { |v1, v2| v1 + v2 }
      vec3.should eq Apatite::Vector[5, 7, 9]
    end
  end

  describe "#covector" do
    it "should create a single row matrix from the vector" do
      vec = Apatite::Vector[1, 2, 3]
      mat = vec.covector

      mat.should be_a Apatite::Matrix(Int32)
      mat.row_count.should eq 1
      mat[0].should eq [1, 2, 3]
    end
  end

  describe "#cross_product" do
    it "should return the cross product of multiple vectors" do
      vec1 = Apatite::Vector[1, 2, 3]
      cross = vec1.cross_product(Apatite::Vector[3, 4, 5])
      cross.should eq Apatite::Vector[-2, 4, -2]
    end
  end

  describe "#inner_product" do
    it "should return the inner product of two vectors" do
      vec = Apatite::Vector[1, 2, 3]
      prod = vec.inner_product(Apatite::Vector[3, 4, 5])
      prod.should eq 26
    end
  end

  describe "#each" do
    it "should iterate over each item in the vector" do
      vec = Apatite::Vector[1, 2, 3]
      index = 0
      vec.each do |n|
        n.should eq index + 1
        index += 1
      end
    end
  end

  describe "#magnitude" do
    it "should return the modulus of a vector" do
      vec = Apatite::Vector[1, 2, 3]
      vec.magnitude.should eq 3.7416573867739413
    end
  end

  describe "#normalize" do
    it "should return a vector with the same direction, but norm 1" do
      vec = Apatite::Vector[1, 2, 3]
      vec.normalize.should eq Apatite::Vector[0.2672612419124244, 0.5345224838248488, 0.8017837257372732]
    end
  end

  describe "#round" do
    it "should round each entry in the vector" do
      vec = Apatite::Vector[0.2672612419124244, 0.5345224838248488, 0.8017837257372732]
      vec.round(2).should eq Apatite::Vector[0.27, 0.53, 0.80]
    end
  end

  describe "#coerce" do
    it "should return a new vector with elements of a different type" do
      vec = Apatite::Vector[1, 2, 3]
      flt = vec.coerce(Float64)
      flt.should be_a Apatite::Vector(Float64)
    end

    it "should work with big rationals" do
      vec = Apatite::Vector[1, 2, 3]
      rat = vec.coerce(BigRational, 2)
      rat.should be_a Apatite::Vector(BigRational)
    end

    it "should work with complex numbers" do
      vec = Apatite::Vector[1, 2, 3]
      com = vec.coerce(Complex, 1)
      com.should be_a Apatite::Vector(Complex)
    end
  end
end
