/*==============================================================================
LESSON 13 — CAPSTONE PROJECT
Lesson 14 of 14 — Stata Curriculum for Survey Researchers
(folder is "13_capstone" because the curriculum folders are 0-indexed)

ASSIGNMENT BRIEF:
    You have been asked to produce a short, defensible analysis of the survey
    in data/survey_clean.dta for a non-technical stakeholder audience. Using
    everything from Lessons 00-12, complete the FOUR required steps below and
    write up your interpretation in comments as you go. This is SELF-DIRECTED:
    the analytical commands are left as `* TODO:` placeholders for you to
    fill in. There is no single correct answer for step 3 (the advanced
    method) — choose the path that interests you most.

    An "INSTRUCTOR ANSWER KEY (illustrative)" worked example lives at the
    bottom of this file inside an `if 0 { ... }` block so it will NOT execute
    when you run this do-file. Attempt the assignment yourself first; use the
    answer key to check your approach afterward, not as a starting point.

PREREQUISITES:
    - All of Lessons 00-12. In particular:
        Lesson 02 — produced survey_clean.dta (data prep, already done for you)
        Lesson 04 — tabulate/proportion, `ci proportions`, reading CIs
        Lesson 05 — svyset, pweight vs. fweight/iweight
        Lesson 08-09 — regress/logit and their `svy:` counterparts
        Lesson 10 — ologit/mlogit for categorical outcomes
        Lesson 11 — dominance analysis (domin/domme) for relative importance
        Lesson 12 — gsem lclass for latent class analysis

REQUIRED STEPS:
    1. Weighted descriptives with confidence intervals for at least one
       variable of your choice, correctly interpreted in a comment.
    2. At least one weighted regression using `svy:` and the design declared
       below, with a plain-language interpretation of the key coefficient(s).
    3. ONE advanced method of your choosing:
         (a) ordinal (`ologit`) or multinomial (`mlogit`) regression, OR
         (b) dominance analysis (`domin`/`domme`), OR
         (c) latent class analysis (`gsem lclass`)
       with an interpretation of what it adds beyond steps 1-2.
    4. A short written interpretation (as comments) tying steps 1-3 together
       for a non-technical reader: what did you learn, and what would you
       tell a stakeholder who has never seen a p-value?

ESTIMATED TIME: 45 minutes (self-directed)
==============================================================================*/


* --- 0. Setup: load the canonical cleaned dataset & declare the design ------
* (This part is done for you — it is exactly the same on every lesson from
* Lesson 02 onward. See Lesson 02 for how survey_clean.dta was produced, and
* Lesson 05 for what each piece of `svyset` means.)

capture log close
clear all
set more off

use "../../data/survey_clean.dta", clear

svyset psu [pweight=weight], strata(region)   // see Lesson 05 for svyset syntax
svydescribe                                   // sanity check: strata/PSU counts


* --- 1. Weighted descriptives with confidence intervals ----------------------
* Pick at least one variable (categorical or continuous) and produce a
* correctly weighted point estimate with a confidence interval.
* // see Lesson 04 for `ci proportions` / `svy: proportion` and how to read a CI
* // see Lesson 05 for why weighted estimates differ from unweighted ones
* // see Lesson 06 if you choose a two-way tabulation (row vs. column %)

* TODO: produce at least one weighted descriptive statistic with a CI, e.g.
*   svy: proportion policy_support
*   svy: mean satisfaction
* TODO: in a comment below, state the point estimate, the CI, and what the
*   CI means in plain language (NOT "95% chance the true value is in this
*   range" — see Lesson 04 for the correct interpretation)

* // YOUR INTERPRETATION:
* //


* --- 2. At least one weighted regression -------------------------------------
* // see Lesson 08 for the unweighted version of this model and how to read
*    coefficients / odds ratios
* // see Lesson 09 for `svy: regress` / `svy: logit`, subpop() vs if, and why
*    design-based SEs usually differ from naive ones

* TODO: fit at least one regression using `svy:` on an outcome of your
*   choice (policy_support, voted_last_election, or satisfaction), e.g.
*   svy: regress satisfaction age income_k i.educ_raw trust_gov
*   svy: logit voted_last_election age i.educ_raw

* // YOUR INTERPRETATION (plain language, one key coefficient):
* //


* --- 3. One advanced method of your choice -----------------------------------
* Choose ONE path (a), (b), or (c). Delete or comment out the ones you do
* not use.

* (a) Ordinal or multinomial regression
* // see Lesson 10 for ologit/mlogit syntax, cutpoints, and the
*    proportional-odds ("parallel lines") assumption
* TODO (a): e.g. ologit policy_support trust_gov trust_media trust_science ///
*                trust_local age i.educ_raw
* TODO (a): check the parallel-lines assumption with `omodel` (ssc install
*   omodel — see Lesson 03 for `ssc install` and Lesson 10 for `omodel`)

* (b) Dominance analysis
* // see Lesson 11 for domin/domme syntax and Shapley-style decomposition of
*    R-squared or pseudo-R-squared across predictors
* TODO (b): e.g. domin satisfaction age income_k trust_gov trust_media, ///
*                reg
* TODO (b): ssc install domin  (or domme) — see Lesson 03 and Lesson 11

* (c) Latent class analysis
* // see Lesson 12 for `gsem lclass`, choosing the number of classes via
*    BIC/AIC, and posterior class assignment
* TODO (c): e.g. gsem (trust_gov trust_media trust_science trust_local <-), ///
*                lclass(C 2)
* TODO (c): compare BIC/AIC across a 2-class and 3-class solution before
*   settling on a final number of classes

* // YOUR INTERPRETATION (what did the advanced method add beyond steps 1-2?):
* //


* --- 4. Written interpretation for a non-technical stakeholder ---------------
* In 4-8 sentences (as comments), summarize what you found across steps 1-3
* for someone who has never seen a p-value or a confidence interval. Be
* specific about your actual numbers, not just the method.

* // STAKEHOLDER SUMMARY:
* //
* //
* //


* ============ YOUR TURN IS DONE — COMPARE TO THE ANSWER KEY BELOW ============
* The block below never runs automatically (`if 0`). Highlight lines inside
* it and run selectively if you want to try the instructor's path, or just
* read it after finishing your own attempt above.

if 0 {

    /*==========================================================================
    INSTRUCTOR ANSWER KEY (illustrative)
    This is ONE possible solution path (regression + ordinal/dominance
    combination), not the only correct one. Your variable choices, your
    advanced-method choice, and your write-up can legitimately differ.
    ==========================================================================*/

    clear all
    use "../../data/survey_clean.dta", clear
    svyset psu [pweight=weight], strata(region)
    svydescribe

    * --- 1. Weighted descriptives with CIs ---
    svy: proportion policy_support
    * Reading this: each row is the weighted share of respondents in that
    * policy_support category, with a design-based 95% CI. E.g. if the
    * "Strongly support" row shows 0.31 [0.27, 0.35], we would say: "our
    * best estimate is that 31% of the target population strongly supports
    * the policy; if we repeated this survey design many times, about 95%
    * of the intervals we'd construct this way would contain the true
    * population share" — NOT "there's a 95% chance the true value is
    * between 27% and 35%."

    svy: mean satisfaction
    * Weighted mean satisfaction (0-10 scale) with a design-based CI.

    * --- 2. Weighted regression ---
    svy: regress satisfaction age income_k i.educ_raw trust_gov trust_local
    * Interpretation (illustrative numbers — yours will differ): holding
    * age, income, education, and other trust measures fixed, a one-point
    * increase in trust_gov is associated with a statistically meaningful
    * increase in predicted satisfaction (check the coefficient's CI:
    * does it exclude 0?). This is a DESIGN-BASED estimate — see Lesson 09
    * for why we did not just run `regress` here.

    * --- 3. Advanced method: ordinal regression + dominance analysis ---
    * (a) Ordinal regression on policy_support
    ologit policy_support trust_gov trust_media trust_science trust_local ///
        age i.educ_raw
    * cutpoints /cut1 </cut2 </cut3 should be increasing; check that first.

    capture ssc install omodel
    omodel ologit policy_support trust_gov trust_media trust_science ///
        trust_local age i.educ_raw
    * A small p-value on the omodel test would suggest the proportional-odds
    * assumption is shaky and a `gologit2` model (Lesson 10) might fit
    * better; a large p-value is reassuring for the simpler ologit.

    margins, predict(outcome(4)) atmeans
    * Predicted probability of "Strongly support" at average predictor
    * values — a stakeholder-friendly number to report alongside the model.

    * (b) Dominance analysis on the same regression from step 2, to rank
    * predictors by relative importance (illustrative call — see Lesson 11
    * for full options and output interpretation):
    capture ssc install domin
    domin satisfaction age income_k i.educ_raw trust_gov trust_local, reg
    * Reading this: domin reports each predictor's average (Shapley-style)
    * contribution to the model's R-squared across all possible orderings
    * of predictors, so you can say e.g. "trust_gov accounts for the
    * largest share of explained variance in satisfaction among our
    * predictors," which is a claim `regress` coefficients alone cannot
    * support (coefficients depend on scale; dominance weights do not).

    * --- 4. Stakeholder summary (illustrative) ---
    * // About a third of respondents strongly support the policy, with our
    * // survey design giving us reasonable confidence in that estimate.
    * // Average satisfaction sits a bit above the midpoint of the 0-10
    * // scale. People who trust government and local institutions more
    * // tend to report higher satisfaction, even after accounting for
    * // age, income, and education — and trust in government is the
    * // single most important factor among those we measured. Education
    * // level is also linked to how strongly people support the policy,
    * // though the relationship isn't perfectly proportional across every
    * // level of support, which is worth flagging before making strong
    * // claims about any one education group.

} // end instructor answer key
