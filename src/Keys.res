open Rxjs

type keyPress =
  | Up(string)
  | Down(string)

let keyMapObservable = {
  let keydown =
    fromEvent(Obj.magic(window), "keydown")->pipe2(
      map(event => Down(event["key"])),
      distinctUntilChanged(),
    )

  let keyup =
    fromEvent(Obj.magic(window), "keyup")->pipe2(
      map(event => Up(event["key"])),
      distinctUntilChanged(),
    )

  merge(keydown, keyup)->pipe(scan((keys, ev) => {
      switch ev {
      | Down(key) => {
          Set.add(keys, key)
          keys
        }
      | Up(key) => {
          Set.delete(keys, key)->ignore
          keys
        }
      }
    }, Set.make()))
}
