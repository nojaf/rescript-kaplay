open Vitest
open Kaplay

/*
test("create kaplay context", () => {
  let k = Kaplay.Context.kaplay(
    ~initOptions={
      width: 300,
      height: 400,
      global: false,
      background: "#000000",
      scale: 1.,
      crisp: true,
    },
  )
  expect(k)->Expect.toBeDefined

  Pokemon.load(k, 4)
  Pokemon.load(k, 1)
  Ember.load()

  Promise.make((resolve, reject) => {
    k->Kaplay.Context.onError(
      error => {
        reject(error)
      },
    )
    k->Kaplay.Context.onLoad(
      () => {
        let charmander = Pokemon.make(k, ~pokemonId=4, ~level=5, Opponent)
        let bulbasaur = Pokemon.make(k, ~pokemonId=1, ~level=5, Player)
        expect(charmander)->Expect.toBeDefined

        let enemyAI = EnemyAI.make(k, ~pokemonId=4, ~level=5, bulbasaur)

        k->Kaplay.Context.quit

        resolve()
      },
    )
  })
})

test("create kaplay context", () => {
  let k = Kaplay.Context.kaplay(
    ~initOptions={
      width: 300,
      height: 400,
      global: false,
      background: "#000000",
      scale: 1.,
      crisp: true,
    },
  )
  expect(k)->Expect.toBeDefined

  Pokemon.load(k, 4)
  Pokemon.load(k, 1)
  Ember.load()

  Promise.make((resolve, reject) => {
    k->Kaplay.Context.onError(
      error => {
        reject(error)
      },
    )
    k->Kaplay.Context.onLoad(
      () => {
        let charmander = Pokemon.make(k, ~pokemonId=4, ~level=5, Opponent)
        let bulbasaur = Pokemon.make(k, ~pokemonId=1, ~level=5, Player)
        expect(charmander)->Expect.toBeDefined

        let enemyAI = EnemyAI.make(k, ~pokemonId=4, ~level=5, bulbasaur)

        k->Kaplay.Context.quit

        resolve()
      },
    )
  })
})
*/

@send
external thenResolve: (promise<'data>, 'data => unit) => promise<'data> = "then"

@send
external catchJSError: (promise<'data>, JsError.t => unit) => promise<'data> = "catch"

@send
external finally: (promise<'data>, unit => unit) => unit = "finally"

let withKaplayContext = (testFn: Context.t => promise<unit>): promise<unit> => {
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
  Ember.load()

  Promise.make((resolve, reject) => {
    k->Context.onError(error => {
      k->Context.quit
      reject(error)
    })
    k->Context.onLoad(() => {
      testFn(k)
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

test("setup the playing field", () => {
  let tileSize = 32.
  let halfTile = tileSize / 2.

  withKaplayContext(async k => {
    let center = 2. * tileSize + halfTile
    let enemy = Pokemon.make(k, ~pokemonId=4, ~level=5, Opponent)
    enemy->Pokemon.setPos(k->Context.vec2Local(center, halfTile))

    let _ = GenericMove.make(k, ~x=center, ~y=2. * tileSize + halfTile, ~size=tileSize, Player)

    let player = Pokemon.make(k, ~pokemonId=25, ~level=12, Player)
    player->Pokemon.setPos(k->Context.vec2Local(center, tileSize * 4. + halfTile))

    let rs = EnemyAI.makeRuleSystem(k, ~enemy, ~player)

    // Setup spies
    let enemyMoveSpy = vi->Vi.spyOn(rs.state.enemy, "move")

    EnemyAI.update(k, rs, ())

    expect(enemyMoveSpy)->Expect.toHaveBeenCalled
  })
})
