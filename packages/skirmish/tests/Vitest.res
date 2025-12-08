@module("vitest")
external test: (string, unit => promise<unit>) => unit = "test"

module Expect = {
  type t

  @send
  external toBe: (t, 'expected) => unit = "toBe"

  @send
  external toBeDefined: t => unit = "toBeDefined"

  @send
  external toHaveLength: (t, int) => unit = "toHaveLength"

  @send
  external toHaveBeenCalled: t => unit = "toHaveBeenCalled"
}

@module("vitest")
external expect: 'item => Expect.t = "expect"

@module("vitest")
external beforeEach: unit => unit = "beforeEach"

module Spy = {
  type t
}

module Vi = {
  type t

  @send
  external spyOn: (t, 'subject, string) => Spy.t = "spyOn"
}

@module("vitest")
external vi: Vi.t = "vi"
