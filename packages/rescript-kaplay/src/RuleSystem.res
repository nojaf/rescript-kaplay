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
  ~salience: salience=?,
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
  ~salience: salience=?,
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

/**
 * Asserts a fact by **adding** to its current grade.
 * 
 * **Important**: This **adds** to the existing grade, it does not replace it.
 * The grade is clamped to a maximum of 1.0.
 * 
 * Formula: `newGrade = min(1.0, currentGrade + grade)`
 * 
 * If the fact doesn't exist, `currentGrade` is treated as 0.0.
 * 
 * @param fact - The fact to assert
 * @param grade - The grade to add (default: 1.0)
 */
@send
external assertFact: (t<'state>, fact, ~grade: grade=?) => unit = "assertFact"

/**
 * Retracts a fact by **subtracting** from its current grade.
 * 
 * **Important**: This **subtracts** from the existing grade, it does not replace it.
 * The grade is clamped to a minimum of 0.0.
 * 
 * Formula: `newGrade = max(0.0, currentGrade - grade)`
 * 
 * If the fact doesn't exist, `currentGrade` is treated as 0.0.
 * 
 * @param fact - The fact to retract
 * @param grade - The grade to subtract (default: 1.0)
 */
@send
external retractFact: (t<'state>, fact, ~grade: grade=?) => unit = "retractFact"

/**
 * Returns the grade for the specified fact.
 * 
 * **Important**: If the fact doesn't exist in the facts map, returns `Grade(0.0)`.
 * This means non-existent facts are treated as having grade 0.0.
 * 
 * @param fact - The fact to query
 * @returns The grade of the fact, or `Grade(0.0)` if the fact doesn't exist
 */
@send
external gradeForFact: (t<'state>, fact) => grade = "gradeForFact"

/**
 * Returns the minimum grade among the specified facts.
 * 
 * **Important**: If any of the facts don't exist, they are treated as having grade 0.0.
 * This means if you pass facts that don't exist, the minimum will be 0.0.
 * 
 * Example: If `fact1` has grade 0.8 and `fact2` doesn't exist (grade 0.0),
 * the minimum will be 0.0, not 0.8.
 * 
 * @param facts - Array of facts to check
 * @returns The minimum grade among the facts
 */
@send @variadic
external minimumGradeForFacts: (t<'state>, array<fact>) => grade = "minimumGradeForFacts"

/**
 * Returns the maximum grade among the specified facts.
 * 
 * **Important**: If any of the facts don't exist, they are treated as having grade 0.0.
 * This means if all facts don't exist, the maximum will be 0.0.
 * 
 * Example: If `fact1` has grade 0.8 and `fact2` doesn't exist (grade 0.0),
 * the maximum will be 0.8.
 * 
 * @param facts - Array of facts to check
 * @returns The maximum grade among the facts
 */
@send @variadic
external maximumGradeForFacts: (t<'state>, array<fact>) => grade = "maximumGradeForFacts"

/**
 * Clears all facts from the system.
 * 
 * **Important**: This completely clears the facts map. Rules and state are preserved.
 * 
 * If you call `reset()` every frame before `execute()`, you typically don't need
 * retract rules because facts are cleared automatically. You can just assert facts
 * when conditions are true, and they'll be cleared on the next frame if not re-asserted.
 */
@send
external reset: t<'state> => unit = "reset"
