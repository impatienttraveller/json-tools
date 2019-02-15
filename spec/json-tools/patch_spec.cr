require "../spec_helper"

describe Json::Tools::Patch do
  describe "#test" do
    it "root" do
      patch_object = JSON.parse(<<-JSON
      [
        { "op": "test", "path": "/", "value": {"a": 1, "b": "cool"} }
      ]
      JSON
      )
      patch = Json::Tools::Patch.new(patch_object)

      doc = JSON.parse(<<-JSON
      {
        "a": 1,
        "b": "cool"
      }
      JSON
      )
      patched_doc = doc.clone
      patch.apply(patched_doc)

      patched_doc.should eq(doc)
    end

    it "path /a matches a simple value" do
      patch_object = JSON.parse(<<-JSON
        [
          { "op": "test", "path": "/a", "value": 1 }
        ]
        JSON
      )
      patch = Json::Tools::Patch.new(patch_object)

      doc = JSON.parse(<<-JSON
        {
          "a": 1,
          "b": "cool"
        }
        JSON
      )
      patched_doc = doc.clone
      patch.apply(patched_doc)

      patched_doc.should eq(doc)
    end

    it "path /a matches an array value" do
      patch_object = JSON.parse(<<-JSON
        [
          { "op": "test", "path": "/a", "value": [9, "rain", 3.14] }
        ]
        JSON
      )
      patch = Json::Tools::Patch.new(patch_object)

      doc = JSON.parse(<<-JSON
        {
          "a": [9, "rain", 3.14],
          "b": "cool"
        }
        JSON
      )
      patched_doc = doc.clone
      patch.apply(patched_doc)

      patched_doc.should eq(doc)
    end

    it "path /a/1 matches first element of an array value" do
      patch_object = JSON.parse(<<-JSON
        [
          { "op": "test", "path": "/a/1", "value": "rain" }
        ]
        JSON
      )
      patch = Json::Tools::Patch.new(patch_object)

      doc = JSON.parse(<<-JSON
        {
          "a": [9, "rain", 3.14],
          "b": "cool"
        }
        JSON
      )
      patched_doc = doc.clone
      patch.apply(patched_doc)

      patched_doc.should eq(doc)
    end

    it "path /a matches an object value" do
      patch_object = JSON.parse(<<-JSON
        [
          { "op": "test", "path": "/a", "value": [1, {"p1": "rain", "p2": 3.14 }] }
        ]
        JSON
      )
      patch = Json::Tools::Patch.new(patch_object)

      doc = JSON.parse(<<-JSON
        {
          "a": [
            1,
            {
              "p1": "rain",
              "p2": 3.14
            }
          ],
          "b": "cool"
        }
        JSON
      )
      patched_doc = doc.clone
      patch.apply(patched_doc)

      patched_doc.should eq(doc)
    end

    expect_raises(Json::Tools::PointerException, "Unable to access element a of {\"x\" => 1_i64, \"y\" => \"cool\"}") do
      patch_object = JSON.parse(<<-JSON
        [
          { "op": "test", "path": "/a", "value": 1 }
        ]
        JSON
      )
      patch = Json::Tools::Patch.new(patch_object)

      doc = JSON.parse(<<-JSON
        {
          "x": 1,
          "y": "cool"
        }
        JSON
      )
      patch.apply(doc)
    end

    expect_raises(Json::Tools::FailedTestException, "Expected 1 at /a") do
      patch_object = JSON.parse(<<-JSON
        [
          { "op": "test", "path": "/a", "value": 1 }
        ]
        JSON
      )
      patch = Json::Tools::Patch.new(patch_object)

      doc = JSON.parse(<<-JSON
        {
          "a": 2,
          "b": "cool"
        }
        JSON
      )
      patch.apply(doc)
    end
  end

  describe "#remove" do
    it "path /a" do
      patch_object = JSON.parse(<<-JSON
        [
          { "op": "remove", "path": "/a" }
        ]
        JSON
      )
      patch = Json::Tools::Patch.new(patch_object)

      doc = JSON.parse(<<-JSON
        {
          "a": 1,
          "b": "cool"
        }
        JSON
      )
      original_doc = doc.clone
      patched_doc = patch.apply(doc)

      doc.should eq(original_doc)
      patched_doc.should eq(JSON.parse(<<-JSON
        {
          "b": "cool"
        }
        JSON
      ))
    end

    it "path /a/1" do
      patch_object = JSON.parse(<<-JSON
        [
          { "op": "remove", "path": "/a/1" }
        ]
        JSON
      )
      patch = Json::Tools::Patch.new(patch_object)

      doc = JSON.parse(<<-JSON
        {
          "a": [1, "rain", 3.14],
          "b": "cool"
        }
        JSON
      )
      original_doc = doc.clone
      patched_doc = patch.apply(doc)

      doc.should eq(original_doc)
      patched_doc.should eq(JSON.parse(<<-JSON
        {
          "a": [1, 3.14],
          "b": "cool"
        }
        JSON
      ))
    end

    it "path /a/1/p1" do
      patch_object = JSON.parse(<<-JSON
        [
          { "op": "remove", "path": "/a/1/p1" }
        ]
        JSON
      )
      patch = Json::Tools::Patch.new(patch_object)

      doc = JSON.parse(<<-JSON
        {
          "a": [
            1,
            {
              "p1": "rain",
              "p2": 3.14
            }
          ],
          "b": "cool"
        }
        JSON
      )
      original_doc = doc.clone
      patched_doc = patch.apply(doc)

      doc.should eq(original_doc)
      patched_doc.should eq(JSON.parse(<<-JSON
        {
          "a": [
            1,
            {
              "p2": 3.14
            }
          ],
          "b": "cool"
        }
        JSON
      ))
    end

    expect_raises(Json::Tools::IllegalOperationException, "This pointer is the root of the document") do
      patch_object = JSON.parse(<<-JSON
        [
          { "op": "remove", "path": "/" }
        ]
        JSON
      )
      patch = Json::Tools::Patch.new(patch_object)

      doc = JSON.parse(<<-JSON
        {
          "a": 1,
          "b": "cool"
        }
        JSON
      )
      patch.apply(doc)
    end

    expect_raises(Json::Tools::OutOfBoundsException, "Index 10 of [1_i64, 2_i64] is out of bounds") do
      patch_object = JSON.parse(<<-JSON
        [
          { "op": "remove", "path": "/a/10" }
        ]
        JSON
      )
      patch = Json::Tools::Patch.new(patch_object)

      doc = JSON.parse(<<-JSON
        {
          "a": [1, 2],
          "b": "cool"
        }
        JSON
      )
      patch.apply(doc)
    end

    expect_raises(Json::Tools::MissingPropertyException, "Property c of {\"a\" => 1_i64, \"b\" => \"cool\"} is unknown") do
      patch_object = JSON.parse(<<-JSON
        [
          { "op": "remove", "path": "/c" }
        ]
        JSON
      )
      patch = Json::Tools::Patch.new(patch_object)

      doc = JSON.parse(<<-JSON
        {
          "a": 1,
          "b": "cool"
        }
        JSON
      )
      patch.apply(doc)
    end
  end

  describe "#add" do
    it "path /b as simple value" do
      patch_object = JSON.parse(<<-JSON
        [
          { "op": "add", "path": "/b", "value": "cool" }
        ]
        JSON
      )
      patch = Json::Tools::Patch.new(patch_object)

      doc = JSON.parse(<<-JSON
        {
          "a": 1
        }
        JSON
      )
      original_doc = doc.clone
      patched_doc = patch.apply(doc)

      doc.should eq(original_doc)
      patched_doc.should eq(JSON.parse(<<-JSON
        {
          "a": 1,
          "b": "cool"
        }
        JSON
      ))
    end

    it "path /b/1 to array" do
      patch_object = JSON.parse(<<-JSON
        [
          { "op": "add", "path": "/b/1", "value": "new" }
        ]
        JSON
      )
      patch = Json::Tools::Patch.new(patch_object)

      doc = JSON.parse(<<-JSON
        {
          "a": 1,
          "b": [1, "rain", 3.14]
        }
        JSON
      )
      original_doc = doc.clone
      patched_doc = patch.apply(doc)

      doc.should eq(original_doc)
      patched_doc.should eq(JSON.parse(<<-JSON
        {
          "a": 1,
          "b": [1, "new", "rain", 3.14]
        }
        JSON
      ))
    end

    it "path /b/1/p1" do
      patch_object = JSON.parse(<<-JSON
        [
          { "op": "add", "path": "/b/1/p1", "value": ["new", 1] }
        ]
        JSON
      )
      patch = Json::Tools::Patch.new(patch_object)

      doc = JSON.parse(<<-JSON
        {
          "a": [1, "rain"],
          "b": [
            "cool",
            {
              "p2": 3.14
            }
          ]
        }
        JSON
      )
      original_doc = doc.clone
      patched_doc = patch.apply(doc)

      doc.should eq(original_doc)
      patched_doc.should eq(JSON.parse(<<-JSON
        {
          "a": [1, "rain"],
          "b": [
            "cool",
            {
              "p1": ["new", 1],
              "p2": 3.14
            }
          ]
        }
        JSON
      ))
    end

    it "path /b/1/p1 when exists" do
      patch_object = JSON.parse(<<-JSON
        [
          { "op": "add", "path": "/b/1/p1", "value": "val" }
        ]
        JSON
      )
      patch = Json::Tools::Patch.new(patch_object)

      doc = JSON.parse(<<-JSON
        {
          "a": [1, "rain"],
          "b": [
            "cool",
            {
              "p1": ["new", 1],
              "p2": 3.14
            }
          ]
        }
        JSON
      )
      original_doc = doc.clone
      patched_doc = patch.apply(doc)

      doc.should eq(original_doc)
      patched_doc.should eq(JSON.parse(<<-JSON
        {
          "a": [1, "rain"],
          "b": [
            "cool",
            {
              "p1": "val",
              "p2": 3.14
            }
          ]
        }
        JSON
      ))
    end

    expect_raises(Json::Tools::OutOfBoundsException, "Index 10 of [\"cool\", \"rain\"] is out of bounds") do
      patch_object = JSON.parse(<<-JSON
        [
          { "op": "add", "path": "/b/10", "value": 10 }
        ]
        JSON
      )
      patch = Json::Tools::Patch.new(patch_object)

      doc = JSON.parse(<<-JSON
        {
          "a": 1,
          "b": ["cool", "rain"]
        }
        JSON
      )
      patch.apply(doc)
    end
  end

  describe "#replace" do
    it "path /c as simple value" do
      patch_object = JSON.parse(<<-JSON
        [
          { "op": "replace", "path": "/c", "value": "2" }
        ]
        JSON
      )
      patch = Json::Tools::Patch.new(patch_object)

      doc = JSON.parse(<<-JSON
        {
          "b": 5,
          "c": 6
        }
        JSON
      )
      original_doc = doc.clone
      patched_doc = patch.apply(doc)

      doc.should eq(original_doc)
      patched_doc.should eq(JSON.parse(<<-JSON
        {
          "b": 5,
          "c": "2"
        }
        JSON
      ))
    end

    it "path /c/1 on array" do
      patch_object = JSON.parse(<<-JSON
        [
          { "op": "replace", "path": "/c/1", "value": "new" }
        ]
        JSON
      )
      patch = Json::Tools::Patch.new(patch_object)

      doc = JSON.parse(<<-JSON
        {
          "b": 1,
          "c": [1, "rain"]
        }
        JSON
      )
      original_doc = doc.clone
      patched_doc = patch.apply(doc)

      doc.should eq(original_doc)
      patched_doc.should eq(JSON.parse(<<-JSON
        {
          "b": 1,
          "c": [1, "new"]
        }
        JSON
      ))
    end

    it "path /c/1/p1" do
      patch_object = JSON.parse(<<-JSON
        [
          { "op": "replace", "path": "/c/1/p1", "value": ["new", 1] }
        ]
        JSON
      )
      patch = Json::Tools::Patch.new(patch_object)

      doc = JSON.parse(<<-JSON
        {
          "b": [1, "rain"],
          "c": [
            "cool",
            {
              "p1": 3.14
            }
          ]
        }
        JSON
      )
      original_doc = doc.clone
      patched_doc = patch.apply(doc)

      doc.should eq(original_doc)
      patched_doc.should eq(JSON.parse(<<-JSON
        {
          "b": [1, "rain"],
          "c": [
            "cool",
            {
              "p1": ["new", 1]
            }
          ]
        }
        JSON
      ))
    end

    expect_raises(Json::Tools::PointerException, "Unable to access element 10 of [\"cool\", \"rain\"]") do
      patch_object = JSON.parse(<<-JSON
        [
          { "op": "replace", "path": "/c/10", "value": 10 }
        ]
        JSON
      )
      patch = Json::Tools::Patch.new(patch_object)

      doc = JSON.parse(<<-JSON
        {
          "b": 1,
          "c": ["cool", "rain"]
        }
        JSON
      )
      patch.apply(doc)
    end

    expect_raises(Json::Tools::PointerException, "Unable to access element c of {\"b\" => 1_i64}") do
      patch_object = JSON.parse(<<-JSON
        [
          { "op": "replace", "path": "/c", "value": 10 }
        ]
        JSON
      )
      patch = Json::Tools::Patch.new(patch_object)

      doc = JSON.parse(<<-JSON
        {
          "b": 1
        }
        JSON
      )
      patch.apply(doc)
    end

    expect_raises(Json::Tools::PointerException, "Unable to access element 2 of [\"cool\", \"rain\"]") do
      patch_object = JSON.parse(<<-JSON
        [
          { "op": "replace", "path": "/c/2", "value": 10 }
        ]
        JSON
      )
      patch = Json::Tools::Patch.new(patch_object)

      doc = JSON.parse(<<-JSON
        {
          "c": ["cool", "rain"]
        }
        JSON
      )
      patch.apply(doc)
    end

    expect_raises(Json::Tools::PointerException, "Unable to access element p2 of {\"p1\" => 3.14}") do
      patch_object = JSON.parse(<<-JSON
        [
          { "op": "replace", "path": "/c/1/p2", "value": "a" }
        ]
        JSON
      )
      patch = Json::Tools::Patch.new(patch_object)

      doc = JSON.parse(<<-JSON
        {
          "b": [1, "rain"],
          "c": [
            "cool",
            {
              "p1": 3.14
            }
          ]
        }
        JSON
      )
      patch.apply(doc)
    end
  end

  describe "#copy" do
    it "path /a to /b" do
      patch_object = JSON.parse(<<-JSON
        [
          { "op": "copy", "from": "/a", "path": "/b" }
        ]
        JSON
      )
      patch = Json::Tools::Patch.new(patch_object)

      doc = JSON.parse(<<-JSON
        {
          "a": 1
        }
        JSON
      )
      original_doc = doc.clone
      patched_doc = patch.apply(doc)

      doc.should eq(original_doc)
      patched_doc.should eq(JSON.parse(<<-JSON
        {
          "a": 1,
          "b": 1
        }
        JSON
      ))
    end

    it "path /a/1 to /b" do
      patch_object = JSON.parse(<<-JSON
        [
          { "op": "copy", "from": "/a/1", "path": "/b" }
        ]
        JSON
      )
      patch = Json::Tools::Patch.new(patch_object)

      doc = JSON.parse(<<-JSON
        {
          "a": [1, 3, 5]
        }
        JSON
      )
      original_doc = doc.clone
      patched_doc = patch.apply(doc)

      doc.should eq(original_doc)
      patched_doc.should eq(JSON.parse(<<-JSON
        {
          "a": [1, 3, 5],
          "b": 3
        }
        JSON
      ))
    end

    it "path /a/1 to /b/0" do
      patch_object = JSON.parse(<<-JSON
        [
          { "op": "copy", "from": "/a/1", "path": "/b/0" }
        ]
        JSON
      )
      patch = Json::Tools::Patch.new(patch_object)

      doc = JSON.parse(<<-JSON
        {
          "a": [1, 3, 5],
          "b": [5, 7]
        }
        JSON
      )
      original_doc = doc.clone
      patched_doc = patch.apply(doc)

      doc.should eq(original_doc)
      patched_doc.should eq(JSON.parse(<<-JSON
        {
          "a": [1, 3, 5],
          "b": [3, 5, 7]
        }
        JSON
      ))
    end

    expect_raises(Json::Tools::PointerException, "Unable to access element c of {\"a\" => [1_i64, 3_i64, 5_i64]}") do
      patch_object = JSON.parse(<<-JSON
        [
          { "op": "copy", "from": "/c", "path": "/a/0" }
        ]
        JSON
      )
      patch = Json::Tools::Patch.new(patch_object)

      doc = JSON.parse(<<-JSON
        {
          "a": [1, 3, 5]
        }
        JSON
      )
      patch.apply(doc)
    end
  end

  describe "#move" do
    it "path /a to /b" do
      patch_object = JSON.parse(<<-JSON
        [
          { "op": "move", "from": "/a", "path": "/b" }
        ]
        JSON
      )
      patch = Json::Tools::Patch.new(patch_object)

      doc = JSON.parse(<<-JSON
        {
          "a": 1
        }
        JSON
      )
      original_doc = doc.clone
      patched_doc = patch.apply(doc)

      doc.should eq(original_doc)
      patched_doc.should eq(JSON.parse(<<-JSON
        {
          "b": 1
        }
        JSON
      ))
    end

    it "path /a/1 to /b" do
      patch_object = JSON.parse(<<-JSON
        [
          { "op": "move", "from": "/a/1", "path": "/b" }
        ]
        JSON
      )
      patch = Json::Tools::Patch.new(patch_object)

      doc = JSON.parse(<<-JSON
        {
          "a": [1, 3, 5]
        }
        JSON
      )
      original_doc = doc.clone
      patched_doc = patch.apply(doc)

      doc.should eq(original_doc)
      patched_doc.should eq(JSON.parse(<<-JSON
        {
          "a": [1, 5],
          "b": 3
        }
        JSON
      ))
    end

    it "path /a/1 to /b/0" do
      patch_object = JSON.parse(<<-JSON
        [
          { "op": "move", "from": "/a/1", "path": "/b/0" }
        ]
        JSON
      )
      patch = Json::Tools::Patch.new(patch_object)

      doc = JSON.parse(<<-JSON
        {
          "a": [1, 3, 5],
          "b": [7]
        }
        JSON
      )
      original_doc = doc.clone
      patched_doc = patch.apply(doc)

      doc.should eq(original_doc)
      patched_doc.should eq(JSON.parse(<<-JSON
        {
          "a": [1, 5],
          "b": [3, 7]
        }
        JSON
      ))
    end
  end

  it "Multiple operations" do
    patch_object = JSON.parse(<<-JSON
      [
        { "op": "copy", "from": "/c/c~11", "path": "/b/1" },
        { "op": "test", "path": "/b/0", "value": "1st" },
        { "op": "test", "path": "/b/1", "value": "abc" },
        { "op": "test", "path": "/b/2", "value": 7 },
        { "op": "test", "path": "/b/3", "value": 3.14 },
        { "op": "add", "path": "/e", "value": ["new"] },
        { "op": "remove", "path": "/a" },
        { "op": "replace", "path": "/d/1/d~00", "value": "porp" },
        { "op": "move", "from": "/d/1/d|1", "path": "/e/1" }
      ]
      JSON
    )
    patch = Json::Tools::Patch.new(patch_object)

    doc = JSON.parse(<<-JSON
      {
        "a": 1,
        "b": ["1st", 7, 3.14],
        "c": {
          "c/1": "abc",
          "c%2": [890, "xyz"],
          "c^3": 1.2
        },
        "d": [
          6,
          {
            "d~0": "prop",
            "d|1": "erty"
          },
          4
        ]
      }
      JSON
    )
    original_doc = doc.clone
    patched_doc = patch.apply(doc)

    doc.should eq(original_doc)
    patched_doc.should eq(JSON.parse(<<-JSON
      {
        "b": ["1st", "abc", 7, 3.14],
        "c": {
          "c/1": "abc",
          "c%2": [890, "xyz"],
          "c^3": 1.2
        },
        "d": [
          6,
          {
            "d~0": "porp"
          },
          4
        ],
        "e": ["new", "erty"]
      }
      JSON
    ))
  end
end
