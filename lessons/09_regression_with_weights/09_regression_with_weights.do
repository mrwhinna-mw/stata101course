/*==============================================================================
LESSON 09 — REGRESSION WITH SURVEY WEIGHTS & DESIGN
Lesson 9 of 14 — Stata Curriculum for Survey Researchers

PREREQUISITES:
    - Lesson 05 (weighting basics — `svyset`, pweights)
    - Lesson 08 (introduction to regression — `regress`, `logit`,
      `logistic`, `margins`, unweighted). This lesson re-fits the exact
      same two models from Lesson 08, adding the survey design back in.

LEARNING OBJECTIVES:
    - Re-fit the Lesson 08 OLS and logit models as `svy: regress` and
      `svy: logit`, using the design set up with `svyset`
    - Compare design-based standard errors/significance directly against
      the unweighted Lesson 08 results, and explain WHY they typically
      differ (usually larger under the design, though not always)
    - Explain why ignoring the survey design understates uncertainty
    - Correctly restrict an `svy:` model to a subgroup using `subpop()`,
      and understand why using `if` to subset instead is a common and
      serious mistake with `svy:` commands
    - Get design-based predicted probabilities with `svy: margins`

ESTIMATED TIME: 40 minutes
==============================================================================*/


* --- 0. Setup ---------------------------------------------------------------
clear all
set more off

use "../../data/survey_clean.dta", clear     // same cleaned dataset as Lesson 08

* Declare the survey design: psu is the cluster, weight is the sampling
* (probability) weight, region is the stratum. Every `svy:` command below
* uses this design until you `svyset` something different or clear it.
svyset psu [pweight=weight], strata(region)

svydescribe                                  // sanity check: strata/PSU counts, missing design info


* --- 1. Re-fitting the OLS model under the survey design --------------------

* Same right-hand side as Lesson 08's `regress satisfaction age income_k
* i.educ_raw` — only difference is the `svy:` prefix, which tells Stata to
* use the design declared above (weights + clustering + stratification)
* when computing point estimates and, especially, standard errors.
svy: regress satisfaction age income_k i.educ_raw
* COMPARE THIS TO LESSON 08:
* The point estimates (coefficients) will typically be fairly close to the
* unweighted Lesson 08 numbers, but the STANDARD ERRORS usually will not
* match. Design-based SEs are usually LARGER than the naive (unweighted,
* i.i.d.-assumption) SEs from Lesson 08, because:
*   - Clustering (respondents sampled within the same psu tend to be more
*     similar to each other than to a random respondent elsewhere), which
*     reduces the effective sample size and, most of the time, inflates
*     variance relative to assuming independence.
*   - Unequal weights increase variance of the weighted estimator relative
*     to a simple average, when the weights themselves are variable.
* It IS possible for a design-based SE to come out smaller than the naive
* one — this happens when stratification buys you more precision than
* clustering costs you (a small or negative overall "design effect"). But
* the common pattern in practice, and the safe assumption if you haven't
* checked, is that ignoring the design UNDERSTATES your true uncertainty,
* which can make a result look statistically significant when it should
* not. That's the whole reason we svyset in the first place.


* --- 2. Re-fitting the logit model under the survey design ------------------

svy: logit voted_last_election age i.educ_raw
* Again, compare the standard errors and p-values here to the unweighted
* `logit` from Lesson 08. If a predictor was "just barely" significant in
* Lesson 08, it is not unusual for it to lose significance once the design
* is accounted for — this is a real, common experience, not a mistake.
*
* (If you want odds ratios under the design, `svy: logistic` also works,
* the same way `logistic` related to `logit` in Lesson 08 — not repeated
* here to keep this lesson focused.)


* --- 3. Restricting to a subgroup: subpop() vs. if — READ CAREFULLY ---------

* Suppose you only want the model fit among, say, women (female == 1).
* THE WRONG WAY (do not do this with svy: commands):
*
*     svy: regress satisfaction age income_k i.educ_raw if female == 1
*
* This LOOKS like ordinary Stata filtering and Stata will not stop you, but
* it silently drops the excluded observations from the variance
* calculation entirely — as if respondents outside the subgroup had never
* been sampled at all. That throws away information the design carries
* about the FULL sample (e.g., how strata/PSUs were built, how many total
* PSUs contributed) and can produce biased/too-small variance estimates,
* especially when the subgroup is not spread evenly across strata and PSUs.
*
* THE RIGHT WAY: use the `subpop()` option instead. `subpop()` keeps every
* sampled observation in the variance calculation (so the full design
* structure is preserved) and only reports the coefficient/mean estimates
* for the subgroup you asked for.
svy, subpop(if female == 1): regress satisfaction age income_k i.educ_raw
* Under the hood this fits the model correctly accounting for the fact
* that "female == 1" is a SUBPOPULATION of a sample that was designed
* around the whole target population, not its own independent survey.
* The point estimates from `subpop()` and from the naive `if` approach will
* often look similar; it's the standard errors (and therefore your
* confidence intervals and p-values) that can diverge, sometimes
* substantially. When in doubt, always prefer `subpop()` for subgroup
* analysis with any `svy:` command.


* --- 4. Design-based predicted probabilities with svy: margins --------------

* Just like `margins` in Lesson 08, but design-aware: standard errors and
* CIs on the predicted values now reflect the survey design too.
svy: logit voted_last_election age i.educ_raw
svy: margins educ_raw
* Read this the same way you read Lesson 08's `margins educ_raw` output —
* predicted probability of having voted at each education level, holding
* age at each observation's own value — except these SEs/CIs are now
* design-based and appropriate for statements about the sampled population.


* ============ YOUR TURN ============
* Pick ONE of the two models above (the `svy: regress` satisfaction model
* or the `svy: logit` voting model). Refit it restricted to a subgroup of
* your choosing (for example, a specific region, or age above/below some
* cutoff) using `subpop()` CORRECTLY (not `if`). Then write a comment
* comparing the subgroup result to the full-sample model above: are the
* coefficients similar? Are the standard errors/CIs noticeably wider (as
* you'd expect with a smaller effective sample)?
*
* Example skeleton (fill in your own subgroup condition):
*
* svy, subpop(if region == 2): logit voted_last_election age i.educ_raw
* // comparison: ...
