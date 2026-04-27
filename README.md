> [!WARNING]
> **This project is archived.**
>
> This was an experiment in building ReScript bindings for Kaplay. After building a substantial binding layer (~2,500 lines) and a sample game on top of it, the conclusion is that ReScript is not a good fit for this kind of game engine.
>
> **Why?**
>
> - **Kaplay's component system is inherently dynamic.** Game objects gain and lose capabilities at runtime, which conflicts with ReScript's static type model.
> - **The bindings rely heavily on escape hatches.** Functions like `Obj.magic` and `%identity` appear throughout the codebase to bridge the gap between what Kaplay does and what ReScript's type system expects. For example, narrowing a game object to a specific component looks like this:
>
>   ```rescript
>   if obj->has("pos") {
>     Some(Obj.magic(obj))  // runtime cast, not compile-time safety
>   }
>   ```
>
>   This means you're not actually getting type safety where it matters most.
> - **Binding maintenance is a moving target.** Kaplay's API surface is large and changes over time. Keeping bindings in sync is constant work.
> - **Developer experience suffers.** Time spent working around the type system is time not spent building the game.
> - **Kaplay was designed with TypeScript's model in mind.** Structural typing, `this`-bound callbacks, and optional chaining align naturally with how Kaplay works.
>
> If you're building something with Kaplay, the best experience is using it directly with TypeScript.
>
> The code in this repo is left as-is for anyone curious about the approach. The `skirmish` sample game is incomplete but may be useful as a reference.
