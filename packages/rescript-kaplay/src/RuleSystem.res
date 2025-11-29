@unboxed
type fact = Fact(string)

@unboxed
type grade = Grade(float)

@unboxed
type salience = Salience(bool)

type predicate = fact => bool
type action = fact => unit

type rec t<'state> = {
  //
  agenda: array<rule>,
  state: 'state,
  facts: Map.t<fact, grade>,
}
and rule = {
  predicate: predicate,
  salience: salience,
}

@new
external make: t<'state> = "make"

module Rule = {
  @send
  external evaluate: (rule, t<'state>) => bool = "evaluate"

  @send
  external execute: (rule, t<'state>) => unit = "execute"
}

/** Adds a rule which runs an action if its predicate evaluates to true. */
@send
external addRuleExecutingAction: (t<'state>, predicate, action, ~salient: salience=?) => unit =
  "addRuleExecutingAction"

/** Add a rule which asserts a fact if its predicate evaluates to true. */
@send
external addRuleAssertingFact: (t<'state>, predicate, fact, ~grade: grade=?) => unit =
  "addRuleAssertingFact"

/** Add a rule which retracts a fact if its predicate evaluates to true. */
@send
external addRuleRetractingFact: (
  t<'state>,
  predicate,
  fact,
  ~grade: grade=?,
  ~salient: salience=?,
) => unit = "addRuleRetractingFact"

/** Add a custom rule. */
@send
external addRule: (t<'state>, rule) => unit = "addRule"

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
@send
external minimumGradeForFacts: (t<'state>, array<fact>) => grade = "minimumGradeForFacts"

/** Returns the maximum grade for the specified facts. */
@send
external maximumGradeForFacts: (t<'state>, array<fact>) => grade = "maximumGradeForFacts"

/** Resets the facts */
@send
external reset: t<'state> => unit = "reset"
