/**
 * A fact is a named piece of information stored in the rule system.
 * Facts are identified by a string name and can be asserted or retracted.
 * 
 * Example: `Fact("playerNearby")`, `Fact("lowHealth")`
 */
@unboxed
type fact = Fact(string)

/**
 * A grade represents the strength or confidence of a fact.
 * 
 * **Boundaries**: Grades are clamped to the range [0.0, 1.0]
 * - **0.0**: The fact is not true (or has no confidence)
 * - **1.0**: The fact is fully true (or has maximum confidence)
 * - **Values between 0.0 and 1.0**: Partial truth or confidence levels
 * 
 * Grades can represent:
 * - Binary truth (0.0 = false, 1.0 = true)
 * - Confidence levels (0.5 = 50% confident)
 * - Continuous values as ratios (e.g., space availability: 16px / 32px = 0.5)
 * 
 * Example: `Grade(1.0)` for fully true, `Grade(0.5)` for partial confidence
 */
@unboxed
type grade = Grade(float)

/**
 * Salience controls the execution order of rules.
 * 
 * **Lower salience values execute first** (ascending order).
 * 
 * **Key behavior**: Facts asserted by rules at lower salience values are immediately
 * available to rules at higher salience values in the same execution cycle.
 * This enables derived facts that depend on base facts.
 * 
 * **Recommended strategy**: Use tiered salience values:
 * - `Salience(0.0)` for base facts computed from game state
 * - `Salience(10.0)` for derived facts computed from other facts
 * - `Salience(20.0)` for decision/action rules that use all facts
 * 
 * Example: `Salience(0.0)` executes before `Salience(10.0)`
 */
@unboxed
type salience = Salience(float)

/**
 * The main rule system type that manages rules, facts, and state.
 * 
 * - **`agenda`**: Array of all rules in the system, sorted by salience during execution
 * - **`state`**: Free-form state object where you can store any game state
 * - **`facts`**: Map of facts to their current grades
 */
type rec t<'state> = {
  //
  agenda: array<rule<'state>>,
  mutable state: 'state,
  facts: Map.t<fact, grade>,
}
/**
 * A rule consists of a predicate (condition) and a salience (priority).
 * 
 * When the rule system executes, rules are sorted by salience (ascending),
 * and rules with true predicates execute their actions.
 */
and rule<'state> = {
  predicate: predicate<'state>,
  salience: salience,
}
/**
 * A predicate is a function that evaluates a condition based on the rule system state.
 * Returns `true` if the condition is met, `false` otherwise.
 * 
 * Predicates can read facts, state, and any other information from the rule system.
 */
and predicate<'state> = t<'state> => bool
/**
 * An action is a function that performs some operation when a rule's predicate is true.
 * Actions can assert/retract facts, modify state, or perform any side effects.
 */
and action<'state> = t<'state> => unit

let make: Context.t => t<'state> = %raw(`function (k) { return new k.RuleSystem(); }`)

module Rule = {
  @send
  external evaluate: (rule<'state>, t<'state>) => bool = "evaluate"

  @send
  external execute: (rule<'state>, t<'state>) => unit = "execute"
}

/** Adds a rule which runs an action if its predicate evaluates to true. */
@send
external addRuleExecutingAction: (
  t<'state>,
  predicate<'state>,
  action<'state>,
  ~salient: salience=?,
) => unit = "addRuleExecutingAction"

/** Add a rule which asserts a fact if its predicate evaluates to true. */
@send
external addRuleAssertingFact: (t<'state>, predicate<'state>, fact, ~grade: grade=?) => unit =
  "addRuleAssertingFact"

/** Add a rule which retracts a fact if its predicate evaluates to true. */
@send
external addRuleRetractingFact: (
  t<'state>,
  predicate<'state>,
  fact,
  ~grade: grade=?,
  ~salient: salience=?,
) => unit = "addRuleRetractingFact"

/** Add a custom rule. */
@send
external addRule: (t<'state>, rule<'state>) => unit = "addRule"

/** Removes all rules. */
@send
external removeAllRules: t<'state> => unit = "removeAllRules"

/** Executes all rules for which the predicate evaluates to true. */
@send
external execute: t<'state> => unit = "execute"

/** Asserts a fact. */
@send
external assertFact: (t<'state>, fact, ~grade: grade=?) => unit = "assertFact"

/** Retracts a fact. */
@send
external retractFact: (t<'state>, fact, ~grade: grade=?) => unit = "retractFact"

/** Returns the grade for the specified fact. */
@send
external gradeForFact: (t<'state>, fact) => grade = "gradeForFact"

/** Returns the minimum grade for the specified facts. */
@send @variadic
external minimumGradeForFacts: (t<'state>, array<fact>) => grade = "minimumGradeForFacts"

/** Returns the maximum grade for the specified facts. */
@send @variadic
external maximumGradeForFacts: (t<'state>, array<fact>) => grade = "maximumGradeForFacts"

/** Resets the facts */
@send
external reset: t<'state> => unit = "reset"
