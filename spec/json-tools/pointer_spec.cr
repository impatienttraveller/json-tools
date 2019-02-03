require "../spec_helper"

describe Json::Tools::Pointer do
  describe "#eval" do
    it "empty pointer returns the root element" do
      p = Json::Tools::Pointer.new("")

      doc = JSON.parse("[1, 2, 3]")
      element = p.eval(doc)
      element.should eq(doc)
    end

    it "/ pointer returns the root element" do
      p = Json::Tools::Pointer.new("/")
      doc = JSON.parse(<<-JSON
        {
          "a": 1,
          "b": "cool"
        }
        JSON
      )
      element = p.eval(doc)
      element.should eq(doc)
    end

    it "/0 pointer returns the first element of the array" do
      p = Json::Tools::Pointer.new("/0")

      doc = JSON.parse("[1, 2, 3]")
      element = p.eval(doc)
      element.should eq(1)
    end

    it "/a pointer returns the a element" do
      p = Json::Tools::Pointer.new("/a")
      doc = JSON.parse(<<-JSON
        {
          "a": "cool",
          "b": ["abc", "def"],
          "c": []
        }
        JSON
      )
      element = p.eval(doc)
      element.should eq("cool")
    end

    it "/b/0 pointer returns the b[0] element" do
      p = Json::Tools::Pointer.new("/b/0")
      doc = JSON.parse(<<-JSON
        {
          "a": "cool",
          "b": ["abc", "def"],
          "c": []
        }
        JSON
      )
      element = p.eval(doc)
      element.should eq("abc")
    end

    it "/c/2/p2/ pointer returns the value of p2 of the third element of c" do
      p = Json::Tools::Pointer.new("/c/2/p2/")
      doc = JSON.parse(<<-JSON
        {
          "a": "cool",
          "b": ["abc", "def"],
          "c": [
            {
              "p1": 1,
              "p2": "aaa"
            },
            {
              "p1": 2,
              "p2": "bbb"
            },
            {
              "p1": 3,
              "p2": "ccc"
            }
          ]
        }
        JSON
      )
      element = p.eval(doc)
      element.should eq("ccc")
    end

    expect_raises(Json::Tools::PointerException, "Unable to access element a of [1_i64, 2_i64]") do
      p = Json::Tools::Pointer.new("/a")
      doc = JSON.parse("[1, 2]")
      p.eval(doc)
    end

    expect_raises(Json::Tools::PointerException, "Unable to access element b of {\"a\" => \"cool\"}") do
      p = Json::Tools::Pointer.new("/b")
      doc = JSON.parse(<<-JSON
        {
          "a": "cool"
        }
        JSON
      )
      p.eval(doc)
    end

    expect_raises(Json::Tools::PointerException, "Unable to access element 3 of [1_i64, 2_i64]") do
      p = Json::Tools::Pointer.new("/a/3")
      doc = JSON.parse(<<-JSON
        {
          "a": [1, 2]
        }
        JSON
      )
      p.eval(doc)
    end
  end

  describe "#parent" do
    it "parent of pointer /a returns the root element" do
      p = Json::Tools::Pointer.new("/a")
      doc = JSON.parse(<<-JSON
        {
          "a": "awesome"
        }
        JSON
      )
      parent = p.parent
      element = parent.eval(doc)
      element.should eq(doc)
      parent.path.should eq("/")
    end

    it "parent of pointer /a/0 returns the /a element" do
      p = Json::Tools::Pointer.new("/a/0")
      doc = JSON.parse(<<-JSON
        {
          "a": [1,2,3]
        }
        JSON
      )
      parent = p.parent
      element = parent.eval(doc)
      element.should eq(JSON.parse("[1,2,3]"))
      parent.path.should eq("/a/")
    end

    expect_raises(Json::Tools::IllegalOperationException, "This pointer is the root of the document") do
      p = Json::Tools::Pointer.new("/")
      doc = JSON.parse("[1,2,3]")
      p.parent.eval(doc)
    end

    expect_raises(Json::Tools::IllegalOperationException, "This pointer is the root of the document") do
      p = Json::Tools::Pointer.new("")
      doc = JSON.parse(<<-JSON
        {
          "a": [1,2,3]
        }
        JSON
      )
      p.parent.eval(doc)
    end
  end

  describe "#key" do
    it "key of pointer / returns blank" do
      p = Json::Tools::Pointer.new("/")
      p.key.should eq("")
    end

    it "key of pointer /a returns a" do
      p = Json::Tools::Pointer.new("/a")
      p.key.should eq("a")
    end

    it "key of pointer /a/0 returns 0" do
      p = Json::Tools::Pointer.new("/a/0")
      p.key.should eq("0")
    end
  end
end
