local util = require("spec.util")

describe("[]", function()
   describe("on records", function()
      it("ok if indexing by string", util.check [[
         local x = { foo = "f" }
         print(x["foo"])
      ]])

      it("fails if indexing by a bad type", util.check_type_error([[
         local x = { foo = 123 }
         print(x[true])
      ]], {
         { msg = "cannot index object of type record (foo: integer) with boolean" },
      }))

      it("fails even if record is homogenous", util.check_type_error([[
         local x = { foo = 12, bar = 24 }
         local y = "baz"
         local n: number = x[y]
      ]], {
         { msg = "cannot index object of type record (foo: integer; bar: integer) with a string, consider using an enum" },
      }))

      it("fail without declaration if record is not homogenous", util.check_type_error([[
         local s = string.upper("hello")
         local x = { foo = 12, bar = s }
         local y = "baz"
         local n: string = x[y]
      ]], {
         { msg = "cannot index object of type record (foo: integer; bar: string) with a string, consider using an enum" },
      }))

      it("ok without declaration if key is enum and all keys map to the same type", util.check [[
         local type Keys = enum
            "foo"
            "bar"
         end
         local x = { foo = 12, bar = 24, bla = "something else" }
         local e: Keys = "foo"
         local n: number = x[e]
      ]])

      it("fail if key is enum and not all keys map to the same type", util.check_type_error([[
         local type Keys = enum
            "foo"
            "bar"
         end
         local x = { foo = 12, bar = true, bla = "something else" }
         local e: Keys = "foo"
         local n: number = x[e]
      ]], {
         { msg = "cannot index, not all enum values map to record fields of the same type" },
      }))

      it("fail if key is enum and not all keys are covered", util.check_type_error([[
         local type Keys = enum
            "foo"
            "bar"
            "oops"
         end
         local x = { foo = 12, bar = 12, bla = "something else" }
         local e: Keys = "foo"
         local n: number = x[e]
      ]], {
         { msg = "enum value 'oops' is not a field" },
      }))

      it("fail if indexing by invalid string", util.check_type_error([[
         local x = { foo = "f" }
         print(x["bar"])
      ]], {
         { msg = "invalid key 'bar' in record 'x'" },
      }))
   end)

   describe("on strings", function()
      it("works with relevant stdlib string functions", util.check [[
         local s: string
         s:byte()
         s:find()
         s:format()
         s:gmatch()
         s:gsub()
         s:len()
         s:lower()
         s:match()
         s:pack()
         s:packsize()
         s:rep()
         s:reverse()
         s:sub()
         s:unpack()
         s:upper()
      ]])
   end)

   describe("on enums", function()
      it("works with relevant stdlib string functions", util.check [[
         local type foo = enum
            "bar"
         end
         local s: foo
         s:byte()
         s:find()
         s:format()
         s:gmatch()
         s:gsub()
         s:len()
         s:lower()
         s:match()
         s:pack()
         s:packsize()
         s:rep()
         s:reverse()
         s:sub()
         s:unpack()
         s:upper()
      ]])
   end)

   describe("on tuples", function()
      it("results in the correct type for integer literals", util.check [[
         local t: {string, number} = {"hi", 1}
         local str: string = t[1]
         local num: number = t[2]
      ]])
      it("produces a union when indexed with a number variable", util.check [[
         local t: {string, integer} = {"hi", 1}
         local x = 1
         local var: string | integer = t[x]
      ]])
      it("errors when a union can't be produced from indexing", util.check_type_error([[
         local t: {{string}, {integer}} = {{"hey"}, {1}}
         local x = 1
         local var = t[x]
      ]], {
         { msg = "cannot index this tuple with a variable because it would produce a union type that cannot be discriminated at runtime" },
      }))
   end)

   describe("on maps", function()
      it("checks index keys nominally, not structurally (regression test for #533)", util.check_type_error([[
         local type IndexType = record
            x: number
         end
         local type WrongType = record
         end
         local type MapType = {IndexType: number}

         local wrong_var: WrongType = {}
         local index_var: IndexType = {}
         local map: MapType = {[index_var] = 42}

         print(map[wrong_var])
      ]], {
         { msg = "wrong index type: got WrongType, expected IndexType" },
      }))

      it("checks index keys nominally for inferred empty tables", util.check_type_error([[
         local type IndexType = record
            x: number
         end
         local type WrongType = record
         end

         local wrong_var: WrongType = {}
         local index_var: IndexType = {}
         local map = {}
         map[index_var] = 42
         map[wrong_var] = 43
      ]], {
         { msg = "wrong index type: got WrongType, expected IndexType" },
      }))

      it("checks index keys nominally for inferred empty tables", util.check_type_error([[
         local type IndexType = record
            x: number
         end
         local type WrongType = record
         end

         local wrong_var: WrongType = {}
         local index_var: IndexType = {}

         local function f<T, U>(a: T, b: U)
         end

         local map = {}
         f(map[index_var], map[wrong_var])
      ]], {
         { msg = "inconsistent index type: got WrongType, expected IndexType" },
      }))
   end)
end)
