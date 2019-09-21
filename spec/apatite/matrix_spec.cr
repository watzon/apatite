require "../spec_helper"

describe "Apatite::Matrix" do
  describe ".map_with_index" do
    it "returns a new matrix with each element processed according to their indexes" do
      matrix = Apatite::Matrix[[1, 2], [3, 4]]
      matrix.map_with_index { |e, i, j| e*i + j }.should eq Apatite::Matrix[[0, 1], [3, 5]]
    end
  end
end
