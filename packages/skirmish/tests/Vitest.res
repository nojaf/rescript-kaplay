@module("vitest")
external test: (string, unit => promise<unit>) => unit = "test"

module Expect = {
  type t

  @send
  external toBeDefined: t => unit = "toBeDefined"
}

@module("vitest")
external expect: 'item => Expect.t = "expect"
