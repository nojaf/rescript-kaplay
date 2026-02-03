open Vitest
open Kaplay

@send
external thenResolve: (promise<'data>, 'data => unit) => promise<'data> = "then"

@send
external catchJSError: (promise<'data>, JsError.t => unit) => promise<'data> = "catch"

@send
external finally: (promise<'data>, unit => unit) => unit = "finally"

let withKaplayContext = (
  playingField: array<string>,
  ~enemyMove1: PkmnMove.t=ZeroMove.move,
  testFn: (Context.t, RuleSystem.t<RuleSystemState.t>) => promise<unit>,
): promise<unit> => {
  let k = Context.kaplay(
    ~initOptions={
      width: 160,
      height: 160,
      global: false,
      background: "#000000",
      scale: 1.,
      crisp: true,
    },
  )

  // Load assets
  Pokemon.load(k, 4)
  Pokemon.load(k, 25)
  Thundershock.load()
  Ember.load(k)

  Promise.make((resolve, reject) => {
    if Array.length(playingField) == 0 {
      reject(JsError.make("Playing field is empty"))
    }
    if {
      let xDimension = Array.getUnsafe(playingField, 0)->String.length
      !Array.every(playingField, row => String.length(row) == xDimension)
    } {
      reject(JsError.make("All rows must have the same length"))
    }

    // https://v4000.kaplayjs.com/docs/api/ctx/onError/
    k->Context.onError((error: JsError.t) => {
      k->Context.quit
      reject(error)
    })
    k->Context.onLoad(() => {
      let xDimension = Array.getUnsafe(playingField, 0)->String.length
      let yDimension = Array.length(playingField)
      let tileSize = 32.
      let halfTile = tileSize / 2.

      for y in 0 to yDimension - 1 {
        for x in 0 to xDimension - 1 {
          let tile = Array.getUnsafe(playingField, y)->String.charAt(x)
          let (x, y) = (Int.toFloat(x), Int.toFloat(y))

          switch tile {
          | "P" => {
              let x = x * tileSize + halfTile
              let y = y * tileSize + halfTile
              let player = Pokemon.make(k, ~pokemonId=25, ~level=12, Player)
              player->Pokemon.setPos(k->Context.vec2Local(x, y))
            }
          | "E" => {
              let x = x * tileSize + halfTile
              let y = y * tileSize + halfTile
              let enemy = Pokemon.make(k, ~pokemonId=4, ~level=5, ~move1=enemyMove1, Opponent)
              enemy->Pokemon.setPos(k->Context.vec2Local(x, y))
            }
          | "A" => {
              let x = x * tileSize + halfTile
              let y = y * tileSize + halfTile
              GenericMove.make(k, ~x, ~y, ~size=tileSize, Player)->ignore
            }
          | "." => ()
          | _ => reject(JsError.make(`Invalid tile: ${tile}, expected P, E, A, .`))
          }
        }
      }

      let enemies = k->Context.query({include_: [Pokemon.tag, Team.opponent]})
      if enemies->Array.length !== 1 {
        reject(
          JsError.make(`Expected exactly 1 enemy, found ${enemies->Array.length->Int.toString}`),
        )
      }

      let players = k->Context.query({include_: [Pokemon.tag, Team.player]})
      if players->Array.length !== 1 {
        reject(
          JsError.make(`Expected exactly 1 player, found ${players->Array.length->Int.toString}`),
        )
      }

      let rs = EnemyAI.makeRuleSystem(
        k,
        ~enemy=enemies->Array.getUnsafe(0),
        ~player=players->Array.getUnsafe(0),
      )

      testFn(k, rs)
      ->thenResolve(resolve)
      ->catchJSError(reject)
      ->finally(
        () => {
          k->Context.quit
        },
      )
      ->ignore
    })
  })
}

test("player attack right in center of enemy", () => {
  withKaplayContext(
    [
      // game level
      "..E..",
      ".....",
      "..A..",
      ".....",
      "..P..",
    ],
    async (k, rs) => {
      // Setup spies
      let enemyMoveSpy = vi->Vi.spyOn(rs.state.enemy, "move")

      EnemyAI.update(k, rs, ())

      expect(rs.state.horizontalMovement)->Expect.toBe(RuleSystemState.Right)
      expect(enemyMoveSpy)->Expect.toHaveBeenCalled
    },
  )
})

test("player attack on the right of enemy", () => {
  withKaplayContext(
    [
      // game level
      "..E..",
      ".....",
      "....A",
      ".....",
      "..P..",
    ],
    async (k, rs) => {
      EnemyAI.update(k, rs, ())

      expect(rs.state.horizontalMovement)->Expect.toBeUndefined
      expect(rs.facts->Map.has(AIFacts.attackOnTheRightOfEnemy))->Expect.toBeTruthy
    },
  )
})

test("player attack on the left of enemy", () => {
  withKaplayContext(
    [
      // game level
      "..E..",
      ".....",
      "A....",
      ".....",
      "..P..",
    ],
    async (k, rs) => {
      EnemyAI.update(k, rs, ())

      expect(rs.state.horizontalMovement)->Expect.toBeUndefined
      expect(rs.facts->Map.has(AIFacts.attackOnTheLeftOfEnemy))->Expect.toBeTruthy
    },
  )
})

test("enemy should move to the right to be in front of player", () => {
  withKaplayContext(
    [
      // game
      ".E...",
      ".....",
      "....P",
    ],
    async (k, rs) => {
      let enemyMoveSpy = vi->Vi.spyOn(rs.state.enemy, "move")
      EnemyAI.update(k, rs, ())

      expect(rs.state.horizontalMovement)->Expect.toBe(RuleSystemState.Right)
      expect(enemyMoveSpy)->Expect.toHaveBeenCalled
    },
  )
})

test("enemy should move to the left to be in front of player", () => {
  withKaplayContext(
    [
      // game
      "....E",
      ".....",
      "P....",
    ],
    async (k, rs) => {
      let enemyMoveSpy = vi->Vi.spyOn(rs.state.enemy, "move")
      EnemyAI.update(k, rs, ())

      expect(rs.state.horizontalMovement)->Expect.toBe(RuleSystemState.Left)
      expect(enemyMoveSpy)->Expect.toHaveBeenCalled
    },
  )
})

test("enemy should not move when in front of player", () => {
  withKaplayContext(
    [
      // game
      ".E.",
      ".P.",
    ],
    async (k, rs) => {
      let enemyMoveSpy = vi->Vi.spyOn(rs.state.enemy, "move")
      EnemyAI.update(k, rs, ())

      expect(rs.state.horizontalMovement)->Expect.toBeUndefined
      expect(enemyMoveSpy)->Expect.not->Expect.toHaveBeenCalled
      // When aligned, player position facts should not be asserted
      expect(rs.facts->Map.has(AIFacts.isPlayerLeft))->Expect.toBeFalsy
      expect(rs.facts->Map.has(AIFacts.isPlayerRight))->Expect.toBeFalsy
    },
  )
})

test("enemy should attack when not under threat and can attack", () => {
  withKaplayContext(
    [
      // game level - enemy and player aligned, no attacks
      "..E..",
      ".....",
      "..P..",
    ],
    ~enemyMove1=Ember.move,
    async (k, rs) => {
      // Ensure enemy can attack
      rs.state.enemy.attackStatus = Pokemon.CanAttack([0, 1, 2, 3])

      EnemyAI.update(k, rs, ())

      // Query for enemy attacks (Team.opponent)
      let enemyAttacks =
        k
        ->Context.query({
          include_: [Attack.tag, Team.opponent],
          hierarchy: Descendants,
        })
        ->Array.filterMap(Attack.Unit.fromGameObj)

      expect(enemyAttacks->Array.length)->Expect.toBe(1)
      expect(rs.facts->Map.has(EnemyAI.AttackFacts.shouldAttack))->Expect.toBeTruthy
    },
  )
})

test("enemy should not attack when under threat", () => {
  withKaplayContext(
    [
      // game level - enemy with center attack
      "..E..",
      "..A..", // Attack in center
      "..P..",
    ],
    async (k, rs) => {
      rs.state.enemy.attackStatus = Pokemon.CanAttack([0, 1, 2, 3])

      EnemyAI.update(k, rs, ())

      let enemyAttacks =
        k
        ->Context.query({
          include_: [Attack.tag, Team.opponent],
          hierarchy: Descendants,
        })
        ->Array.filterMap(Attack.Unit.fromGameObj)

      expect(enemyAttacks->Array.length)->Expect.toBe(0)
    },
  )
})

test("enemy should not attack when already attacking", () => {
  withKaplayContext(["..E..", ".....", "..P.."], async (k, rs) => {
    // Enemy is already attacking
    rs.state.enemy.attackStatus = Pokemon.CannotAttack

    EnemyAI.update(k, rs, ())

    let enemyAttacks =
      k
      ->Context.query({
        include_: [Attack.tag, Team.opponent],
        hierarchy: Descendants,
      })
      ->Array.filterMap(Attack.Unit.fromGameObj)

    expect(enemyAttacks->Array.length)->Expect.toBe(0)
  })
})
