open Kaplay
open GameContext

type t = {
  mutable healthPercentage: float,
  mutable tweenControllerRef?: TweenController.t,
  name: string,
  level: int,
  team: Team.t,
  pokemon: Pokemon.t,
}

external initialState: t => Types.comp = "%identity"

include Pos.Comp({type t = t})

let good = k->Color.fromHex("#00bc7d") // green
let middle = k->Color.fromHex("#ffdf20") // yellow
let bad = k->Color.fromHex("#e7000b") // red

let middleUpperLimit = 60.
let middleLowerLimit = 20.

let getHealthColor = (healthPercent: float): Color.t => {
  switch healthPercent {
  | hp if hp >= middleUpperLimit => {
      // Interpolate between good (100%) and middle (70%)
      // At 100%: t=0 (pure good), at 70%: t=1 (pure middle)
      // Range: 100 - 70 = 30 percentage points
      let t = (100. -. hp) /. (100. -. middleUpperLimit)
      good->Color.lerp(middle, t)
    }
  | hp if hp >= middleLowerLimit => {
      // Interpolate between middle (70%) and bad (20%)
      // At 70%: t=0 (pure middle), at 20%: t=1 (pure bad)
      // Range: 70 - 20 = 50 percentage points
      let t = (middleUpperLimit -. hp) /. (middleUpperLimit -. middleLowerLimit)
      middle->Color.lerp(bad, t)
    }
  | _ => // Below 20%, use bad color
    bad
  }
}

let setHealth = (healthbar: t, targetPercent: float) => {
  // Cancel any existing tween
  switch healthbar.tweenControllerRef {
  | None => ()
  | Some(controller) => controller->TweenController.cancel
  }

  // Start tween from current animated value to target
  let controller = k->Context.tweenWithController(
    ~from=healthbar.healthPercentage,
    ~to_=targetPercent,
    ~duration=0.33,
    ~setValue=value => {
      healthbar.healthPercentage = value
    },
    ~easeFunc=k.easings.easeOutSine,
  )

  // Clear the ref when tween completes
  controller->TweenController.onEnd(() => {
    healthbar.tweenControllerRef = None
  })

  healthbar.tweenControllerRef = Some(controller)
}

// Layout constants for player healthbar
module Layout = {
  // Padding around the moves grid
  let moveGridPaddingX = 3.
  let moveGridPaddingY = 3.
  let moveGridGap = 3.

  // Move cell layout
  let ppFontSize = 12.
  let moveNameFontSize = 11.
  let moveLineSpacing = 6.
  let cellHeight = ppFontSize + moveNameFontSize + moveLineSpacing * 3.
  let cellPaddingX = 8.
  let numRows = 2.
  let emptySlotFontSize = 8.

  // Move cell background colors
  let cellBgLight = "#fafaf9"
  let cellBgDark = "#f3f4f6"
  let cellCooldownBg = "#94a3b8"

  // Moves/NameHP split ratio
  let movesSectionRatio = 0.7
  let nameHpSectionRatio = 0.3

  // Player name/HP section
  let nameFontSize = 12.
  let levelFontSize = 10.
  let hpBarHeight = 8.
  let hpLabelWidth = 22.
  let hpLabelFontSize = 8.
  let sectionSpacing = 4.
  let nameHpPaddingX = 5.
  let separatorWidth = 2.

  // Total height = padding top + 2 rows + padding bottom
  let playerHeight = moveGridPaddingY * 2. + cellHeight * numRows
}

// Layout constants for opponent healthbar
module OpponentLayout = {
  let paddingX = 5.
  let lineY = 40.
  let lineWidth = 2.

  let nameFontSize = 14.
  let nameY = 0.

  let levelFontSize = 10.
  let levelX = 70.
  let levelY = 16.

  let hpLabelFontSize = 8.
  let hpLabelX = 5.
  let hpLabelY = 28.

  let hpBarX = 30.
  let hpBarY = 30.
  let hpBarWidth = 100.
  let hpBarHeight = 5.

  let height = 60.
}

let keyLabels = ["j", "k", "l", ";"]

let drawMove = (
  slot: PkmnMove.moveSlot,
  keyLabel: string,
  x: float,
  y: float,
  cellWidth: float,
  cellHeight: float,
) => {
  let centerX = x + cellWidth / 2.
  let centerY = y + cellHeight / 2.

  // Calculate vertical offsets based on font sizes
  let totalContentHeight = Layout.ppFontSize + Layout.moveNameFontSize + Layout.moveLineSpacing
  let ppY = centerY - totalContentHeight / 2. + Layout.ppFontSize / 2.
  let nameY = centerY + totalContentHeight / 2. - Layout.moveNameFontSize / 2.

  if slot.move.id == -1 {
    // Empty slot: (key) ---
    k->Context.drawText({
      pos: k->Context.vec2Local(centerX, centerY),
      anchor: Context.makeDrawAnchorFromString("center"),
      text: "(" ++ keyLabel ++ ") ---",
      size: Layout.emptySlotFontSize,
      color: k->Color.fromHex("#9ca3af"),
      font: PkmnFont.font,
    })
  } else {
    // Line 1: hotkey and PP/MaxPP spread across the cell (like flexbox space-around)
    let hotkeyText = "(" ++ keyLabel->String.toUpperCase ++ ")"
    let ppFractionText = Int.toString(slot.currentPP) ++ "/" ++ Int.toString(slot.move.maxPP)

    // Hotkey near left edge
    k->Context.drawText({
      pos: k->Context.vec2Local(x +. Layout.cellPaddingX, ppY),
      anchor: Context.makeDrawAnchorFromString("left"),
      text: hotkeyText,
      size: Layout.ppFontSize,
      color: k->Color.black,
      font: PkmnFont.font,
    })

    // PP fraction near right edge
    k->Context.drawText({
      pos: k->Context.vec2Local(x +. cellWidth -. Layout.cellPaddingX, ppY),
      anchor: Context.makeDrawAnchorFromString("right"),
      text: ppFractionText,
      size: Layout.ppFontSize,
      color: slot.currentPP > 0 ? k->Color.black : bad,
      font: PkmnFont.font,
    })

    // Line 2: Move name
    k->Context.drawText({
      pos: k->Context.vec2Local(centerX, nameY),
      anchor: Context.makeDrawAnchorFromString("center"),
      text: slot.move.name,
      size: Layout.moveNameFontSize,
      color: k->Color.black,
      font: PkmnFont.font,
    })
  }
}

let drawMoves = (healthbar: t, movesWidth: float) => {
  let pokemon = healthbar.pokemon
  let moveSlots = [pokemon.moveSlot1, pokemon.moveSlot2, pokemon.moveSlot3, pokemon.moveSlot4]

  // 2x2 grid layout with gap between cells
  let cellWidth = (movesWidth -. Layout.moveGridPaddingX *. 2. -. Layout.moveGridGap) /. 2.
  let cellHeight = (Layout.cellHeight *. 2. -. Layout.moveGridGap) /. 2.

  let debugColors = ["#ff0000", "#00ff00", "#0000ff", "#ffff00"]

  // Alternating background colors for move cells
  let bgLight = k->Color.fromHex(Layout.cellBgLight)
  let bgDark = k->Color.fromHex(Layout.cellBgDark)
  let cooldownBg = k->Color.fromHex(Layout.cellCooldownBg)
  let currentTime = k->Context.time

  moveSlots->Array.forEachWithIndex((slot, index) => {
    let col = mod(index, 2)
    let row = index / 2
    let x = Layout.moveGridPaddingX +. Int.toFloat(col) *. (cellWidth +. Layout.moveGridGap)
    let y = Layout.moveGridPaddingY +. Int.toFloat(row) *. (cellHeight +. Layout.moveGridGap)

    // Cell background - alternating colors (0 and 2 are darker)
    let bgColor = index == 0 || index == 3 ? bgDark : bgLight
    k->Context.drawRect({
      pos: k->Context.vec2Local(x, y),
      width: cellWidth,
      height: cellHeight,
      color: bgColor,
    })

    // Cooldown overlay - shrinks from left to right as cooldown progresses
    if slot.move.id != -1 && slot.move.coolDownDuration > 0. {
      let timeSinceUse = currentTime - slot.lastUsedAt
      let cooldownRemaining = slot.move.coolDownDuration - timeSinceUse
      if cooldownRemaining > 0. {
        let cooldownProgress = cooldownRemaining / slot.move.coolDownDuration
        let overlayWidth = cellWidth * cooldownProgress
        k->Context.drawRect({
          pos: k->Context.vec2Local(x, y),
          width: overlayWidth,
          height: cellHeight,
          color: cooldownBg,
          opacity: 0.5,
        })
      }
    }

    // Debug rectangle for each move cell
    if k.debug.inspect {
      let debugColor = debugColors->Array.get(index)->Option.getOr("#000000")
      k->Context.drawRect({
        pos: k->Context.vec2Local(x, y),
        width: cellWidth,
        height: cellHeight,
        color: k->Color.fromHex(debugColor),
        opacity: 0.3,
      })
    }

    let keyLabel = keyLabels->Array.get(index)->Option.getOr("?")
    drawMove(slot, keyLabel, x, y, cellWidth, cellHeight)
  })
}

let draw =
  @this
  (healthbar: t) => {
    if healthbar.team == Team.Player {
      // Player layout: moves on left, name/HP on right
      let totalWidth = k->Context.width
      let totalHeight = Layout.playerHeight
      let movesWidth = totalWidth * Layout.movesSectionRatio
      let nameHpWidth = totalWidth * Layout.nameHpSectionRatio
      let nameHpX = movesWidth
      let nameHpCenterX = nameHpX + nameHpWidth / 2.

      // Debug rectangles to visualize layout
      if k.debug.inspect {
        k->Context.drawRect({
          pos: k->Context.vec2Local(0., 0.),
          width: movesWidth,
          height: totalHeight,
          color: k->Color.fromHex("#ff0000"),
          opacity: 0.2,
        })
        k->Context.drawRect({
          pos: k->Context.vec2Local(nameHpX, 0.),
          width: nameHpWidth,
          height: totalHeight,
          color: k->Color.fromHex("#0000ff"),
          opacity: 0.2,
        })
      }

      // Draw moves (left side)
      drawMoves(healthbar, movesWidth)
      // Vertical line separator
      k->Context.drawLine({
        p1: k->Context.vec2Local(nameHpX, 0.),
        p2: k->Context.vec2Local(nameHpX, totalHeight),
        color: k->Color.black,
        width: Layout.separatorWidth,
      })

      // Calculate vertical positions dynamically based on content
      let totalContentHeight =
        Layout.nameFontSize + Layout.levelFontSize + Layout.hpBarHeight + Layout.sectionSpacing * 2.
      let contentStartY = (totalHeight - totalContentHeight) / 2.

      let nameY = contentStartY + Layout.nameFontSize / 2.
      let levelY =
        nameY + Layout.nameFontSize / 2. + Layout.sectionSpacing + Layout.levelFontSize / 2.
      let hpY = levelY + Layout.levelFontSize / 2. + Layout.sectionSpacing

      // Pokemon name (centered)
      k->Context.drawText({
        pos: k->Context.vec2Local(nameHpCenterX, nameY),
        anchor: Context.makeDrawAnchorFromString("center"),
        text: healthbar.name->String.toUpperCase,
        letterSpacing: 0.5,
        size: Layout.nameFontSize,
        color: k->Color.black,
        font: PkmnFont.font,
      })

      // Level (smaller, below name)
      k->Context.drawText({
        pos: k->Context.vec2Local(nameHpCenterX, levelY),
        anchor: Context.makeDrawAnchorFromString("center"),
        text: ":L" ++ Int.toString(healthbar.level),
        size: Layout.levelFontSize,
        color: k->Color.black,
        font: PkmnFont.font,
      })

      // HP bar (full width of section with padding)
      let hpBarWidth = nameHpWidth - Layout.nameHpPaddingX * 2. - Layout.hpLabelWidth
      let hpStartX = nameHpX + Layout.nameHpPaddingX

      // HP: label
      k->Context.drawText({
        pos: k->Context.vec2Local(hpStartX, hpY),
        text: "HP:",
        size: Layout.hpLabelFontSize,
        color: k->Color.black,
        font: PkmnFont.font,
      })

      // Healthbar background
      k->Context.drawRect({
        pos: k->Context.vec2Local(hpStartX + Layout.hpLabelWidth, hpY + 2.),
        width: hpBarWidth,
        height: Layout.hpBarHeight,
        radius: [3., 3., 3., 3.],
        color: k->Color.fromHex("#e5e7eb"),
        outline: {
          width: 2.,
          color: k->Color.black,
        },
      })

      // Actual healthbar
      let healthColor = getHealthColor(healthbar.healthPercentage)
      let healthWidth = healthbar.healthPercentage / 100. * hpBarWidth

      k->Context.drawRect({
        pos: k->Context.vec2Local(hpStartX + Layout.hpLabelWidth, hpY + 2.),
        width: healthWidth,
        height: Layout.hpBarHeight,
        radius: [3., 0., 0., 3.],
        color: healthColor,
      })
    } else {
      // Opponent layout: original layout (no moves)
      let lines = [
        k->Context.vec2ZeroLocal,
        k->Context.vec2Local(0., OpponentLayout.lineY),
        k->Context.vec2Local(k->Context.width / 2., OpponentLayout.lineY),
      ]

      k->Context.drawLines({
        pts: lines,
        color: k->Color.black,
        width: OpponentLayout.lineWidth,
      })

      // Pokemon name
      k->Context.drawText({
        pos: k->Context.vec2Local(OpponentLayout.paddingX, OpponentLayout.nameY),
        text: healthbar.name->String.toUpperCase,
        letterSpacing: 0.5,
        size: OpponentLayout.nameFontSize,
        color: k->Color.black,
        font: PkmnFont.font,
      })

      // Pokemon level
      k->Context.drawText({
        pos: k->Context.vec2Local(OpponentLayout.levelX, OpponentLayout.levelY),
        text: ":L" ++ Int.toString(healthbar.level),
        size: OpponentLayout.levelFontSize,
        color: k->Color.black,
        font: PkmnFont.font,
      })

      // HP:
      k->Context.drawText({
        pos: k->Context.vec2Local(OpponentLayout.hpLabelX, OpponentLayout.hpLabelY),
        text: "HP:",
        size: OpponentLayout.hpLabelFontSize,
        color: k->Color.black,
        font: PkmnFont.font,
      })

      // Healthbar background
      k->Context.drawRect({
        pos: k->Context.vec2Local(OpponentLayout.hpBarX, OpponentLayout.hpBarY),
        width: OpponentLayout.hpBarWidth,
        height: OpponentLayout.hpBarHeight,
        radius: [3., 3., 3., 3.],
        color: k->Color.fromHex("#e5e7eb"),
        outline: {
          width: 2.,
          color: k->Color.black,
        },
      })

      // Actual healthbar
      let healthColor = getHealthColor(healthbar.healthPercentage)
      let healthWidth = healthbar.healthPercentage / 100. * OpponentLayout.hpBarWidth

      k->Context.drawRect({
        pos: k->Context.vec2Local(OpponentLayout.hpBarX, OpponentLayout.hpBarY),
        width: healthWidth,
        height: OpponentLayout.hpBarHeight,
        radius: [3., 0., 0., 3.],
        color: healthColor,
      })
    }
  }

let make = (pokemon: Pokemon.t) => {
  let healthbar: t = k->Context.add([
    initialState({
      healthPercentage: pokemon->Pokemon.getHealthPercentage,
      name: MetaData.names->Map.get(pokemon.pokemonId)->Option.getOr("???"),
      level: pokemon.level,
      team: pokemon->Pokemon.getTeam,
      pokemon,
    }),
    CustomComponent.make({id: "healthbar", draw}),
    pokemon->Pokemon.getTeam == Team.Opponent
      ? addPos(k, 10., 10.)
      : addPos(k, 0., k->Context.height - Layout.playerHeight),
  ])

  pokemon
  ->Pokemon.onHurt(_deltaHP => {
    let newHealthPercent = pokemon->Pokemon.getHealthPercentage
    setHealth(healthbar, newHealthPercent)
  })
  ->ignore

  healthbar
}
