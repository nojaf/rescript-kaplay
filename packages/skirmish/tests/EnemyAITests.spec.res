open Vitest

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
