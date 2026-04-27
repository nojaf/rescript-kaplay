open Vitest

// Helper to create a test move with configurable properties
let makeTestMove = (~id=1, ~coolDownDuration=1.0, ~maxPP=10): Pokemon.move => {
  id,
  name: "Test Move",
  maxPP,
  baseDamage: 10,
  coolDownDuration,
  cast: (_k, _pkmn) => (),
  addRulesForAI: (_k, _rs, _slot, _facts) => (),
}

// Helper to create a move slot with configurable state
let makeTestSlot = (
  ~move: Pokemon.move,
  ~currentPP: int,
  ~lastUsedAt=neg_infinity,
): Pokemon.moveSlot => {
  move,
  currentPP,
  lastUsedAt,
}

// =============================================================================
// PkmnMove.canCast tests
// =============================================================================

test("canCast returns true when PP > 0, not ZeroMove, and cooldown elapsed", () => {
  let move = makeTestMove(~coolDownDuration=1.0)
  let slot = makeTestSlot(~move, ~currentPP=5, ~lastUsedAt=0.0)
  let currentTime = 2.0 // 2 seconds have passed, cooldown (1s) has elapsed

  expect(PkmnMove.canCast(slot, currentTime))->Expect.toBe(true)
  Promise.resolve()
})

test("canCast returns false when PP is 0", () => {
  let move = makeTestMove(~coolDownDuration=1.0)
  let slot = makeTestSlot(~move, ~currentPP=0, ~lastUsedAt=0.0)
  let currentTime = 2.0

  expect(PkmnMove.canCast(slot, currentTime))->Expect.toBe(false)
  Promise.resolve()
})

test("canCast returns false for ZeroMove (id = -1)", () => {
  let slot = makeTestSlot(~move=ZeroMove.move, ~currentPP=10)
  let currentTime = 100.0

  expect(PkmnMove.canCast(slot, currentTime))->Expect.toBe(false)
  Promise.resolve()
})

test("canCast returns false when cooldown has not elapsed", () => {
  let move = makeTestMove(~coolDownDuration=2.0)
  let slot = makeTestSlot(~move, ~currentPP=5, ~lastUsedAt=1.0)
  let currentTime = 2.0 // Only 1 second has passed, cooldown is 2s

  expect(PkmnMove.canCast(slot, currentTime))->Expect.toBe(false)
  Promise.resolve()
})

test("canCast returns true exactly when cooldown duration has elapsed", () => {
  let move = makeTestMove(~coolDownDuration=2.0)
  let slot = makeTestSlot(~move, ~currentPP=5, ~lastUsedAt=1.0)
  let currentTime = 3.0 // Exactly 2 seconds have passed

  expect(PkmnMove.canCast(slot, currentTime))->Expect.toBe(true)
  Promise.resolve()
})

test("canCast returns true when lastUsedAt is neg_infinity (never used)", () => {
  let move = makeTestMove(~coolDownDuration=10.0)
  let slot = makeTestSlot(~move, ~currentPP=5)
  let currentTime = 0.0

  expect(PkmnMove.canCast(slot, currentTime))->Expect.toBe(true)
  Promise.resolve()
})

// =============================================================================
// Pokemon.getAvailableMoveIndices tests
// =============================================================================

test("getAvailableMoveIndices returns all indices when all moves available", () => {
  let move = makeTestMove()
  let slot1 = makeTestSlot(~move, ~currentPP=10)
  let slot2 = makeTestSlot(~move, ~currentPP=10)
  let slot3 = makeTestSlot(~move, ~currentPP=10)
  let slot4 = makeTestSlot(~move, ~currentPP=10)
  let currentTime = 0.0

  let result = Pkmn.getAvailableMoveIndices(slot1, slot2, slot3, slot4, currentTime)

  expect(result)->Expect.toHaveLength(4)
  expect(result->Array.includes(0))->Expect.toBeTruthy
  expect(result->Array.includes(1))->Expect.toBeTruthy
  expect(result->Array.includes(2))->Expect.toBeTruthy
  expect(result->Array.includes(3))->Expect.toBeTruthy
  Promise.resolve()
})

test("getAvailableMoveIndices returns only available move indices", () => {
  let move = makeTestMove(~coolDownDuration=1.0)
  let slot1 = makeTestSlot(~move, ~currentPP=5) // available
  let slot2 = makeTestSlot(~move, ~currentPP=0) // no PP
  let slot3 = makeTestSlot(~move, ~currentPP=5) // available
  let slot4 = makeTestSlot(~move, ~currentPP=5, ~lastUsedAt=0.5) // on cooldown
  let currentTime = 1.0

  let result = Pkmn.getAvailableMoveIndices(slot1, slot2, slot3, slot4, currentTime)

  expect(result)->Expect.toHaveLength(2)
  expect(result->Array.includes(0))->Expect.toBeTruthy
  expect(result->Array.includes(2))->Expect.toBeTruthy
  Promise.resolve()
})

test("getAvailableMoveIndices returns empty array when no moves available", () => {
  let move = makeTestMove(~coolDownDuration=2.0)
  let slot1 = makeTestSlot(~move, ~currentPP=0)
  let slot2 = makeTestSlot(~move, ~currentPP=0)
  let slot3 = makeTestSlot(~move, ~currentPP=0)
  let slot4 = makeTestSlot(~move, ~currentPP=0)
  let currentTime = 0.0

  let result = Pkmn.getAvailableMoveIndices(slot1, slot2, slot3, slot4, currentTime)

  expect(result)->Expect.toHaveLength(0)
  Promise.resolve()
})

test("getAvailableMoveIndices excludes ZeroMove slots", () => {
  let move = makeTestMove()
  let slot1 = makeTestSlot(~move, ~currentPP=10) // available
  let slot2 = makeTestSlot(~move=ZeroMove.move, ~currentPP=0) // ZeroMove
  let slot3 = makeTestSlot(~move=ZeroMove.move, ~currentPP=0) // ZeroMove
  let slot4 = makeTestSlot(~move=ZeroMove.move, ~currentPP=0) // ZeroMove
  let currentTime = 0.0

  let result = Pkmn.getAvailableMoveIndices(slot1, slot2, slot3, slot4, currentTime)

  expect(result)->Expect.toHaveLength(1)
  expect(result->Array.includes(0))->Expect.toBeTruthy
  Promise.resolve()
})

test("getAvailableMoveIndices with mixed move states", () => {
  let move1 = makeTestMove(~id=1, ~coolDownDuration=1.0)
  let move2 = makeTestMove(~id=2, ~coolDownDuration=2.0)

  let slot1 = makeTestSlot(~move=move1, ~currentPP=3, ~lastUsedAt=0.0) // cooldown elapsed at t=1
  let slot2 = makeTestSlot(~move=move2, ~currentPP=5, ~lastUsedAt=0.5) // cooldown NOT elapsed at t=1 (needs t=2.5)
  let slot3 = makeTestSlot(~move=ZeroMove.move, ~currentPP=0) // ZeroMove
  let slot4 = makeTestSlot(~move=move1, ~currentPP=1) // available (never used)
  let currentTime = 1.0

  let result = Pkmn.getAvailableMoveIndices(slot1, slot2, slot3, slot4, currentTime)

  expect(result)->Expect.toHaveLength(2)
  expect(result->Array.includes(0))->Expect.toBeTruthy
  expect(result->Array.includes(3))->Expect.toBeTruthy
  Promise.resolve()
})
