open Kaplay

type t

include Pos.Comp({type t = t})

let make = (k: Context.t, rs: RuleSystem.t<_>) => {
  k
  ->Context.add([
    addPos(k, 15., k->Context.height - 15.),
    CustomComponent.make({
      id: "debug-rule-system",
      draw: @this
      _ => {
        rs.facts
        ->Map.entries
        ->Iterator.toArray
        ->Array.forEachWithIndex(((RuleSystem.Fact(fact), RuleSystem.Grade(grade)), index) => {
          let posY = -20. * Int.toFloat(index)
          let gradeText = Float.toFixed(grade * 100., ~digits=2)
          let text = `${fact}: ${gradeText}%`
          Context.drawText(
            k,
            {text, size: 15., color: k->Color.white, pos: k->Context.vec2Local(0., posY)},
          )
        })
      },
    }),
  ])
  ->ignore
}
