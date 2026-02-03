# RuleSystem AI

Rule-based AI for decision-making, state mgmt, AI behaviors.

## Init

```rescript
let ai = RuleSystem.make(k)
ai.state = {health: 50} // typed mutable record
```

## Concepts

**Facts**: name (string) + grade (0-1 float). Grade = confidence/strength
**Rules**: predicate + action + salience (lower = exec first)
**Execution**: `execute()` sorts by salience asc, evals predicates, runs actions

## Rule Types

```rescript
// 1. Execute action
ai->addRuleExecutingAction(
  rs => rs.state.health < 30,
  rs => { rs.state.health = rs.state.health + 20 },
  ~salient=Salience(0.0),
)

// 2. Assert fact (fixed grade)
ai->addRuleAssertingFact(
  rs => rs.state.health < 30,
  Fact("lowHealth"),
  ~grade=Grade(1.0),
  ~salient=Salience(0.0),
)

// 3. Retract fact
ai->addRuleRetractingFact(
  rs => rs.state.health >= 30,
  Fact("lowHealth"),
  ~grade=Grade(1.0),
)
```

## Fact Operations

```rescript
// Assert/retract
ai->assertFact(Fact("playerNearby"), ~grade=Grade(0.8))
ai->retractFact(Fact("playerNearby"), ~grade=Grade(0.5))

// Query
switch ai->gradeForFact(Fact("playerNearby")) {
| Grade(g) => Console.log(g)
}

// Multi-fact
ai->minimumGradeForFacts(Fact("f1"), Fact("f2"))
ai->maximumGradeForFacts(Fact("f1"), Fact("f2"))

// Clear all facts (keeps rules/state)
ai->reset()
```

## Assert/Retract Pairs

**Key**: Facts persist until retracted. When predicate becomes false, asserted fact remains unless retracted.

**Need pairs (current state)**:
- Mutually exclusive conditions
- Current state: "playerFar", "lowHealth", "inCombat"
- Temporary conditions: "underAttack", "nearGoal"

```rescript
// ✅ Twofold pattern
ai->addRuleAssertingFact(rs => rs.state.dist > 10.0, Fact("playerFar"), ~grade=Grade(1.0))
ai->addRuleRetractingFact(rs => rs.state.dist <= 10.0, Fact("playerFar"), ~grade=Grade(1.0))
```

**No pairs (persistent knowledge)**:
- Historical events: "playerSeen", "keyCollected"
- Accumulated evidence: "suspiciousActivity"
- Persistent knowledge: "hasVisitedArea"

```rescript
// ✅ No retract needed
ai->addRuleAssertingFact(rs => rs.state.hasLOS, Fact("playerSeen"), ~grade=Grade(1.0))
```

## Salience (Execution Order)

Lower salience = exec first. Facts asserted at lower salience immediately available to higher salience in same `execute()`.

**Tiered approach**:
```rescript
module Salience = {
  let baseFacts = Salience(0.0)      // from game state
  let derivedFacts = Salience(10.0)  // from other facts
  let decisions = Salience(20.0)     // actions
}

// Tier 1: base facts
ai->addRuleAssertingFact(rs => rs.state.attackX < rs.state.enemyX, Fact("attackFromLeft"), ~grade=Grade(1.0), ~salient=Salience.baseFacts)

// Tier 2: derived (reads base facts asserted at 0.0)
ai->addRuleAssertingFact(
  rs => switch gradeForFact(rs, Fact("attackFromLeft")) {
    | Grade(g) => g > 0.0
    | _ => false
  },
  Fact("safeToMoveRight"),
  ~grade=Grade(1.0),
  ~salient=Salience.derivedFacts,
)

// Tier 3: actions (reads all facts)
ai->addRuleExecutingAction(
  rs => switch gradeForFact(rs, Fact("safeToMoveRight")) { | Grade(g) => g > 0.0 | _ => false },
  rs => moveRight(),
  ~salient=Salience.decisions,
)
```

## Fact Decomposition

Break complex facts into focused facts = declarative action handlers.

**Problem**: Broad facts like "attackIncoming" force complex runtime logic in handlers.

**Solution**: Decompose:
- Positional: "attackFromLeft", "attackFromRight", "attackAligned"
- Space (graded 0-1): "moreSpaceOnLeft", "moreSpaceOnRight"
- Derived: "safeToMoveLeft", "safeToMoveRight"

**Benefits**:
- Action handler = check facts, exec simple action
- Rules encode logic via predicates
- Easier to test, more composable

## Dynamic Grades

Use `addRuleExecutingAction` + `assertFact` for grades computed from state:

```rescript
// ❌ addRuleAssertingFact takes fixed ~grade param
ai->addRuleAssertingFact(rs => true, Fact("space"), ~grade=Grade(???)) // can't compute here

// ✅ Use action to compute dynamically
ai->addRuleExecutingAction(
  rs => true,
  rs => {
    let grade = calculateSpaceGrade(rs.state) // dynamic computation
    rs->assertFact(Fact("moreSpaceOnLeft"), ~grade=Grade(grade))
  },
  ~salient=Salience(0.0),
)
```

**When to use**:
- Fixed grade = `addRuleAssertingFact` with `~grade=Grade(1.0)`
- Dynamic (distance, ratios, proximity) = `addRuleExecutingAction` + `assertFact`

## Graded Facts (Continuous Values)

Grades represent continuous values/ratios, not just binary true/false:

```rescript
// Space as ratio: 16px / 32px = 0.5 grade
ai->addRuleExecutingAction(
  rs => true,
  rs => {
    let grade = calculateSpaceGrade(rs.state)
    rs->assertFact(Fact("moreSpaceOnLeft"), ~grade=Grade(grade))
  },
  ~salient=Salience(0.0),
)

// Use in decisions with thresholds
switch (gradeForFact(rs, Fact("attackFromLeft")), gradeForFact(rs, Fact("moreSpaceOnRight"))) {
| (Grade(a), Grade(s)) when a > 0.0 && s > 0.3 => moveRight() // only if enough space
| _ => ()
}
```

## API Summary

**Methods**:
- `addRuleExecutingAction(pred, action, ~salient=?)` - exec action when pred true
- `addRuleAssertingFact(pred, fact, ~grade=?, ~salient=?)` - assert fact when pred true
- `addRuleRetractingFact(pred, fact, ~grade=?, ~salient=?)` - retract fact when pred true
- `addRule(rule)` - custom rule
- `removeAllRules()` - clear all rules
- `execute()` - eval all rules
- `assertFact(fact, ~grade=?)` - assert fact (default grade 1.0)
- `retractFact(fact, ~grade=?)` - retract fact (default grade 1.0)
- `gradeForFact(fact): Grade(float)` - get grade (0.0 if not exists)
- `minimumGradeForFacts(...facts)` - min grade
- `maximumGradeForFacts(...facts)` - max grade
- `reset()` - clear facts (keep rules/state)

**Props**:
- `agenda: Rule[]` - all rules
- `state: any` - game state (typed mutable record)
- `facts: Map<string, number>` - fact -> grade

## Best Practices

1. Meaningful fact names: "playerNearby" not "p1"
2. Assert/retract pairs for state facts (twofold pattern)
3. Tiered salience: 0.0=base, 10.0=derived, 20.0=decisions
4. Simple predicates, break complex into multiple facts
5. Update state before `execute()`
6. `reset()` when transitioning scenes
7. Call `execute()` in `onUpdate()`

## Patterns

**State machine**: Facts = states, rules = transitions
**Fuzzy logic**: Grades = fuzzy concepts (0.5 = "somewhat close")
**Event-driven**: Combine with KAPLAY events, assert facts on events

## Notes

- Facts don't need grade 0.0 assertion - `gradeForFact` returns 0.0 if missing
- Check existence: `rs.facts->Map.has(factName)`
- Multiple sources can assert same fact, grades add (capped at 1.0)
- Facts stored in mutable map, updated immediately during rule exec
