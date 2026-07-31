/*==============================================================================
LESSON 10 — MODELING ORDINAL & CATEGORICAL OUTCOMES
Lesson 10 of 14 — Stata Curriculum for Survey Researchers

PREREQUISITES:
    - Lesson 02 (cleaning and labels) — this lesson uses the cleaned dataset
      produced there, data/survey_clean.dta
    - Lesson 05 (weighting basics) — `svyset`, pweights (referenced, not used)
    - Lessons 08-09 (intro regression, regression with weights) — you already
      know `regress` and `logit`; this lesson extends that to outcomes with
      MORE than two ordered or unordered categories

LEARNING OBJECTIVES:
    - Explain why treating a 4-category ordinal outcome (policy_support) as
      continuous in OLS is a common but flawed shortcut
    - Fit an ordinal logistic regression with `ologit` and read the cutpoints
      (`/cut1`, `/cut2`, `/cut3`) conceptually
    - State the proportional-odds ("parallel lines") assumption in plain
      language and check it with the user-written `omodel` command
    - Know, at a conceptual level, what to do if that assumption fails
      (generalized ordered logit via `gologit2`)
    - Fit a multinomial logistic regression with `mlogit` and explain when
      you would reach for it instead of `ologit`
    - Use `margins` after `ologit` to get predicted probabilities by outcome
      category

ESTIMATED TIME: 45 minutes

NOTE ON SURVEY DESIGN: For pedagogical clarity on the new modeling concepts
    in this lesson, every model below is fit UNWEIGHTED. A full analysis of
    this outcome would combine these methods with `svy:` (e.g. `svy: ologit
    ...`) wherever Stata supports it, using the design already declared with
    `svyset psu [pweight=weight], strata(region)` in Lesson 05.
==============================================================================*/

capture log close
clear   // start from a clean slate

use "../../data/survey_clean.dta", clear   // load the canonical cleaned dataset built in Lesson 02

svyset psu [pweight=weight], strata(region)   // re-declare the survey design as habit; not used by the unweighted models below (see note above)

describe policy_support trust_gov trust_media trust_science trust_local age educ_raw   // confirm our variables and value labels are in memory

tabulate policy_support   // remind ourselves this is a 4-category ORDERED outcome: 1 Strongly oppose ... 4 Strongly support


* --- 1. Why not just use `regress`? ------------------------------------------
* policy_support is coded 1/2/3/4, so it is tempting to hand it straight to
* `regress` as if it were a continuous measure. That is a common shortcut,
* and it is flawed: OLS assumes the distance between category 1 and 2 is the
* same "amount" of the underlying concept as the distance between category 3
* and 4, which is rarely true for an attitude scale — the jump from
* "Strongly oppose" to "Somewhat oppose" is not guaranteed to mean the same
* thing, psychologically, as the jump from "Somewhat support" to "Strongly
* support." OLS on an ordinal outcome can also produce nonsensical
* predicted values (e.g. 4.3, or -0.2) that don't correspond to any real
* category. We fit the ordinal model correctly below instead.


* --- 2. The correct model: ordinal logistic regression (`ologit`) -----------
* `ologit` models the log-odds of being in category k or HIGHER (a
* cumulative logit) as a function of the predictors, using a SINGLE set of
* coefficients across all categories, plus a separate cutpoint (threshold)
* for each category boundary. This respects the ORDER of policy_support
* without assuming the categories are equally spaced.
ologit policy_support trust_gov trust_media trust_science trust_local age i.educ_raw   // ordinal logit: one coefficient per predictor, shared across all category boundaries

* Reading the output:
*   - Each predictor's coefficient is the change in the log-odds of being in
*     a HIGHER category of policy_support (vs. all lower categories
*     combined) for a one-unit increase in that predictor, holding the
*     others fixed. Positive trust_gov coefficient => higher trust in
*     government is associated with higher odds of falling into a
*     higher-support category.
*   - `/cut1`, `/cut2`, `/cut3` are the estimated CUTPOINTS on the latent
*     scale that separate category 1 from 2, 2 from 3, and 3 from 4. They
*     are not coefficients on a predictor — they are the boundaries of an
*     unobserved ("latent") continuous variable that `ologit` assumes
*     underlies the observed 1-4 responses. You will not usually interpret
*     their magnitude directly; their main use is technical (they let the
*     model compute predicted probabilities for each category) and as a
*     sanity check that they are correctly ORDERED (cut1 < cut2 < cut3).


* --- 3. The proportional-odds assumption -------------------------------------
* `ologit` assumes the effect of each predictor is the SAME regardless of
* which category boundary you look at — i.e., trust_gov has the same
* relationship with "category 2 or higher vs. 1" as it does with "category
* 4 vs. 1-3." This is the proportional-odds, or "parallel lines,"
* assumption. If it is violated, a single coefficient per predictor is
* hiding real differences across boundaries, and your inferences about
* "the" effect of a predictor may be misleading for some comparisons.
*
* `omodel` is a well-known USER-WRITTEN command (not shipped with Stata) that
* provides an approximate likelihood-ratio test of the parallel-lines
* assumption for ordinal models. Install it once from SSC:
ssc install omodel   // one-time install of the user-written `omodel` package from SSC

omodel ologit policy_support trust_gov trust_media trust_science trust_local age i.educ_raw   // re-fits the model and reports a test of the parallel-lines assumption

* How to read the `omodel` output: it reports a likelihood-ratio chi-squared
* test comparing the ordinal (parallel-lines) model to a less restrictive
* model that lets coefficients vary across category boundaries. A SMALL
* p-value (conventionally < 0.05) suggests the parallel-lines assumption is
* violated and a single set of coefficients is not adequate.
*
* IF the assumption fails: one common alternative is the generalized ordered
* logit model, fit in Stata with the user-written `gologit2` command (also
* from SSC), which allows some or all predictors' effects to vary across
* category boundaries. We do not fit it in this lesson — just know it
* exists as the next tool to reach for.


* --- 4. What if you treated policy_support as UNORDERED? (`mlogit`) --------
* Multinomial logistic regression (`mlogit`) treats the outcome categories
* as UNORDERED labels and estimates a SEPARATE set of coefficients for each
* category relative to a baseline category, with no assumption that the
* categories have any natural order at all. `mlogit` is the right tool when
* your categories genuinely have no order (e.g. "which of 4 news sources do
* you trust most"). policy_support DOES have a natural order, so fitting it
* here is mostly illustrative — to show you the mechanics and contrast the
* output with `ologit` — not a recommendation to prefer it for this outcome.
mlogit policy_support trust_gov age i.educ_raw, baseoutcome(1)   // multinomial logit: one full set of coefficients for categories 2, 3, and 4, each relative to category 1 ("Strongly oppose")

* Reading the output: you now get THREE blocks of coefficients (one for
* category 2 vs. 1, one for 3 vs. 1, one for 4 vs. 1) instead of the single
* block `ologit` produced. That is a lot more parameters to estimate and
* interpret for the same amount of data, and it throws away the information
* that "Strongly support" is "more support" than "Somewhat support" — which
* is exactly the information the ordinal model uses to be more efficient.
* Because policy_support genuinely IS ordered, `ologit` is the better real
* choice for this outcome; `mlogit` earns its keep only when categories
* truly have no order.


* --- 5. Predicted probabilities after `ologit`: `margins` -------------------
quietly ologit policy_support trust_gov trust_media trust_science trust_local age i.educ_raw   // re-fit the ologit model quietly so `margins` below operates on it

margins, predict(outcome(1)) atmeans   // predicted probability of landing in category 1 ("Strongly oppose") at sample-mean predictor values
margins, predict(outcome(2)) atmeans   // predicted probability of category 2
margins, predict(outcome(3)) atmeans   // predicted probability of category 3
margins, predict(outcome(4)) atmeans   // predicted probability of category 4

* Each `margins` call above gives you the model's predicted probability of
* one specific policy_support category, at the mean of all predictors. The
* four probabilities (approximately) sum to 1. This is often the most
* useful, plain-English summary to hand a non-technical audience: "at
* average levels of trust, age, and education, a respondent has an
* estimated X% chance of strongly supporting the policy."


* ============ YOUR TURN ============
* 1. Refit the ologit model from Section 2, adding ONE additional predictor
*    from the dataset that we have not yet used (for example `female` or
*    `income_k`).
*
*    ologit policy_support trust_gov trust_media trust_science trust_local ///
*        age i.educ_raw <your new predictor here>
*
* 2. Interpret ONE cutpoint from your new model's output (`/cut1`,
*    `/cut2`, or `/cut3`): is it larger or smaller than the corresponding
*    cutpoint in the original model? What does that suggest about how
*    adding your new predictor shifted the model's implied latent scale?
*
* 3. In a comment, write one sentence stating whether you believe the
*    proportional-odds assumption is more or less likely to hold with your
*    new predictor added, and why you think so (you do not need to run
*    `omodel` again to answer this — reason about it conceptually).
