/*==============================================================================
LESSON 11 — DOMINANCE ANALYSIS FOR ORDINAL OUTCOMES
Lesson 11 of 14 — Stata Curriculum for Survey Researchers

PREREQUISITES:
    - Lesson 02 (cleaning and labels) — this lesson uses the cleaned dataset
      produced there, data/survey_clean.dta
    - Lesson 05 (weighting basics) — `svyset`, pweights (referenced, not used)
    - Lesson 10 (modeling ordinal & categorical outcomes) — this lesson picks
      up the SAME `ologit policy_support trust_gov trust_media trust_science
      trust_local age i.educ_raw` model built there and asks a new question
      about it: which predictor matters most?

LEARNING OBJECTIVES:
    - Explain why raw regression coefficients are a misleading guide to
      "relative importance" when predictors are correlated with each other
    - Describe what dominance analysis actually computes: a predictor's
      average incremental contribution to model fit across ALL possible
      subset models containing it, in the spirit of a Shapley-value
      decomposition
    - Distinguish complete, conditional, and general dominance, and know
      that general dominance is the standard headline result reported when
      complete dominance does not hold
    - Run a dominance analysis in Stata with the user-written `domin` command
      from SSC, and know to confirm current option names with `help domin`
      before executing, since exact syntax can vary by package version
    - Interpret dominance weights as shares of the full model's fit
      statistic, and contrast that with "eyeballing" ologit coefficients
    - State the main practical limitation of dominance analysis: it fits
      2^k subset models, which gets slow fast as k grows

ESTIMATED TIME: 45 minutes

NOTE ON SURVEY DESIGN: As in Lesson 10, the model here is fit UNWEIGHTED for
    pedagogical clarity on the new (dominance-analysis) concept. A full
    analysis would combine this approach with `svy:`-based estimation
    wherever the underlying command and `domin`'s `reg()` option support it,
    using the design already declared with `svyset psu [pweight=weight],
    strata(region)` in Lesson 05.
==============================================================================*/

capture log close
clear   // start from a clean slate

use "../../data/survey_clean.dta", clear   // load the canonical cleaned dataset built in Lesson 02

svyset psu [pweight=weight], strata(region)   // re-declare the survey design as habit; not used by the unweighted model below (see note above)

describe policy_support trust_gov trust_media trust_science trust_local age educ_raw   // confirm our variables and value labels are in memory

correlate trust_gov trust_media trust_science trust_local   // the four trust_* items are almost certainly correlated with each other -- this is exactly the situation that makes "relative importance" tricky


* --- 1. The problem: correlated predictors and misleading coefficients ------
* Refit the ologit model from Lesson 10:
ologit policy_support trust_gov trust_media trust_science trust_local age i.educ_raw   // same ordinal model built in Lesson 10

* It is tempting to look at this output and say "trust_science has the
* biggest coefficient, so it must matter most for policy_support." That
* reasoning breaks down when predictors are correlated with each other (as
* the `correlate` output above almost certainly shows for the four trust_*
* items). When predictors share variance, a regression coefficient tells you
* the effect of ONE predictor HOLDING THE OTHERS FIXED — but it does not
* tell you how much unique + shared explanatory power that predictor
* contributes to the model overall, and it can be unstable (changing size,
* or even sign) depending on exactly which other predictors happen to be in
* the model. Two analysts who each drop a different one of the four trust_*
* variables could walk away with two different "biggest coefficient"
* answers, even though nothing about the underlying relationships changed.
*
* Dominance analysis solves this differently: instead of reading off ONE
* coefficient from ONE fitted model, it asks how much a predictor improves
* model FIT (e.g. pseudo-R2), on average, across every possible subset of
* the OTHER predictors that predictor could be added to.


* --- 2. What dominance analysis actually computes ---------------------------
* For k predictors, there are 2^k possible subset models (every combination
* of predictors present or absent). For each predictor X, dominance analysis
* looks at every subset of the OTHER predictors, computes how much adding X
* to that subset improves the fit statistic, and averages that improvement
* across all subsets. This is conceptually the same idea as a Shapley-value
* decomposition from cooperative game theory: each predictor's "payout" is
* its average marginal contribution across every possible coalition
* (subset) of the other predictors.
*
* Three flavors of dominance are usually distinguished:
*   - COMPLETE dominance: predictor A completely dominates predictor B if A
*     improves fit more than B in EVERY SINGLE subset model, with no
*     exceptions. This is the strongest, cleanest claim, but it often does
*     not hold in real data -- some subset somewhere may go the other way.
*   - CONDITIONAL dominance: compares A and B's AVERAGE contribution within
*     each subset SIZE (i.e., averaged separately across all one-predictor
*     subsets, all two-predictor subsets, etc.), then looks at whether A
*     beats B at every subset size.
*   - GENERAL dominance: averages a predictor's contribution across ALL
*     subset sizes at once, producing one single number per predictor (its
*     "dominance weight"). General dominance is the standard headline
*     result researchers report when complete dominance does not hold
*     (which is common) -- it always produces a full ranking, even when
*     complete dominance is ambiguous.
*
* General dominance weights have a convenient property: they sum to the
* full model's fit statistic. So each predictor's weight, divided by the
* total, is directly interpretable as "this predictor's share of the
* model's overall explanatory power."


* --- 3. Running it in Stata: the `domin` command (SSC) ----------------------
* `domin` is a user-written command (Luchman) that automates dominance
* analysis for (in principle) any Stata estimation command. Install it once:
ssc install domin   // one-time install of the user-written `domin` package from SSC

* `domin` lets you specify:
*   - the estimation command to use for every subset model, via `reg()`
*     (here, `ologit`)
*   - the fit statistic to extract and decompose from each fitted subset
*     model, via `fitstat()` -- an "accessor" expression Stata can evaluate
*     after estimation to pull out a single number, such as an `e()` result
*
* For an ologit model, McFadden's pseudo-R2 (`e(r2_p)`, stored automatically
* by Stata after `ologit`) is a reasonable fit statistic to decompose:
domin policy_support trust_gov trust_media trust_science trust_local age i.educ_raw, reg(ologit) fitstat(e(r2_p))   // decompose McFadden pseudo-R2 across all subset models containing each predictor

* IMPORTANT HONESTY NOTE: `domin`'s exact option names (`reg()`, `fitstat()`,
* and others) have evolved across versions of the package, and a companion
* package, `domme`, exists with related but not identical syntax for
* multiple-fit-statistic decomposition. Before running the command above for
* real, run:
*     help domin
* immediately after installing, and confirm the current option names match
* what is shown above. Do not assume this lesson's syntax is pinned to
* whatever version SSC serves you on the day you install it.


* --- 4. Interpreting the output ----------------------------------------------
* `domin` reports, for each predictor, its general dominance weight -- its
* average incremental contribution to the fit statistic (here, pseudo-R2)
* across all subset models. These weights sum (up to rounding) to the FULL
* model's fit statistic value. To turn a predictor's weight into a percent
* of explained model fit, divide its weight by the total and multiply by
* 100.
*
* ILLUSTRATIVE EXAMPLE OUTPUT (fabricated numbers, for teaching purposes
* only -- NOT the result of actually running the command on this dataset):
*
*     Predictor          General dominance weight     % of total
*     ------------------------------------------------------------
*     trust_gov                  0.031                    26%
*     trust_media                0.014                    12%
*     trust_science               0.048                    41%
*     trust_local                0.018                    15%
*     age                        0.004                     3%
*     educ_raw (joint)           0.004                     3%
*     ------------------------------------------------------------
*     Total (= model pseudo-R2)  0.119                   100%
*
* In this illustrative table, trust_science has the largest dominance
* weight and would be reported as the single most important predictor of
* policy_support in this model -- a conclusion you could NOT safely draw
* from coefficient size alone when predictors are correlated.
*
* Contrast this with just eyeballing the `ologit` coefficients from Section
* 1: a coefficient tells you a partial, hold-everything-else-fixed effect,
* conditional on exactly the other predictors in that one model. A
* dominance weight tells you an AVERAGE contribution across every possible
* model, which is a much more defensible summary of "relative importance"
* when your predictors are not independent of each other.


* --- 5. The catch: computational cost ----------------------------------------
* Dominance analysis fits one model per SUBSET of predictors -- 2^k models
* for k predictors, not counting the empty subset. With the 6 "predictor
* slots" in our model (4 trust items + age + educ_raw, which itself expands
* into multiple indicator levels), that is already dozens of ologit models
* being fit behind the scenes for one `domin` call. Every additional
* predictor DOUBLES the number of subset models that must be fit. This is
* the honest, practical limitation of dominance analysis: it is
* computationally expensive, and it can become slow or impractical with
* many predictors, especially with a large dataset or a slow-to-converge
* estimation command. Always budget extra runtime for it, and consider
* dropping clearly irrelevant predictors before decomposing fit across the
* rest.


* ============ YOUR TURN ============
* 1. Looking at the ILLUSTRATIVE dominance weights table in Section 4 above
*    (remember: those numbers are fabricated for teaching purposes, not a
*    real result), write one or two sentences answering: which of the four
*    trust_* variables dominates the others in explaining policy_support
*    according to that table, and by roughly how much (in percentage-of-
*    total-fit terms) does it exceed the next-largest trust_* predictor?
*
* 2. In a comment, explain in your own words why this conclusion about
*    "which trust_* variable matters most" is more defensible than simply
*    comparing the four trust_* coefficients from the `ologit` output in
*    Section 1.
*
* 3. (Optional, conceptual only -- do not need to run `domin` again) If you
*    added a SEVENTH predictor to the model, what would happen to the
*    number of subset models `domin` needs to fit, and roughly how much
*    longer would you expect the command to take to run?
