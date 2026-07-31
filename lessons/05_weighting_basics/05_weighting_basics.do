/*==============================================================================
    LESSON 05 — SURVEY WEIGHTING BASICS
    Lesson 05 of 14 — Stata Curriculum for Survey Researchers

    PREREQUISITES
      - Lessons 00-04 completed.
      - data/survey_clean.dta exists (produced by Lesson 02).

    LEARNING OBJECTIVES
      By the end of this lesson you will be able to:
      - Explain, conceptually, why survey weights exist (unequal selection
        probability, nonresponse adjustment, post-stratification/calibration).
      - Distinguish Stata's four weight types — pweight, fweight, iweight,
        aweight — and explain why pweight is the standard choice for
        survey estimates.
      - Declare a survey design with `svyset`, including PSU, weight, and
        strata.
      - Use the `svy:` prefix to get correctly weighted/design-based
        estimates, and compare them to their unweighted counterparts.
      - Avoid three common weighting mistakes.

    ESTIMATED TIME: ~45 minutes

    A NOTE ON FILE PATHS
      This do-file lives in lessons/05_weighting_basics/. The data lives
      in data/, two levels up. Hence "../../data/...".
==============================================================================*/

version 18
clear all
set more off

use "../../data/survey_clean.dta", clear   // canonical cleaned dataset


* -----------------------------------------------------------------------
* 1. WHY DO SURVEY WEIGHTS EXIST?
*    In real surveys, not every person in the population has an equal
*    chance of ending up in the sample, and not everyone who is sampled
*    actually responds. Weights are a statistical correction for this so
*    that sample estimates better represent the target population.
*    Three conceptually distinct reasons weights get built (a single
*    weight variable may bundle more than one of these together):
*      - DESIGN weights: correct for unequal SELECTION probability
*        (e.g., deliberately oversampling a small region to get enough
*        respondents there).
*      - NONRESPONSE adjustment: corrects for the fact that some sampled
*        people don't respond, and non-response often isn't random
*        (e.g., certain age groups respond less often).
*      - POST-STRATIFICATION / calibration: adjusts the sample so that
*        totals for key variables (age, sex, region, etc.) line up with
*        known population totals (e.g., from the Census).
*    NOTE: the `weight` variable in this teaching dataset is a SYNTHETIC
*    stand-in for illustration. We are not claiming it was built from all
*    three of these real-world processes — treat it as a generic sampling
*    weight for practicing the mechanics.
* -----------------------------------------------------------------------
summarize weight     // get a feel for the range/spread of the weight variable


* -----------------------------------------------------------------------
* 2. STATA'S WEIGHT TAXONOMY: pweight vs. fweight vs. iweight vs. aweight
*    Stata recognizes four kinds of weights, and using the wrong one
*    silently produces the wrong standard errors (even if the point
*    estimate looks similar):
*      - fweight (frequency weight): the weight is a COUNT of how many
*        actual identical observations this row represents (must be a
*        non-negative integer). Used when you have pre-aggregated data
*        where one row stands for N identical individuals.
*      - aweight (analytic weight): inversely proportional to the
*        variance of an observation — common when each row is itself a
*        mean or aggregate with different underlying precision.
*      - iweight (importance weight): a weight with no formal statistical
*        meaning to Stata; it just scales the log-likelihood/objective in
*        certain estimation commands. Used rarely, mostly by programmers.
*      - pweight (probability/sampling weight): the INVERSE of the
*        probability that this observation was selected into the sample.
*        This is the standard choice for survey estimates, because it is
*        what `svyset`/`svy:` expect, and it correctly inflates each
*        respondent to represent the right number of population members
*        while adjusting standard errors for the survey design.
*    For this course, and for essentially all "survey weight" tasks,
*    you will use pweight.
* -----------------------------------------------------------------------
di as txt "This course uses pweight throughout: it represents inverse selection probability."


* -----------------------------------------------------------------------
* 3. DECLARING THE SURVEY DESIGN WITH svyset
*    `svyset` tells Stata, ONCE per session (or per do-file), what your
*    survey's design looks like, so that every subsequent `svy:` command
*    automatically applies the right weighting and variance adjustment.
* -----------------------------------------------------------------------
svyset psu [pweight=weight], strata(region)
* Breaking that command down piece by piece:
*   - psu             -> the PRIMARY SAMPLING UNIT / cluster variable.
*                         Observations within the same psu are treated as
*                         correlated (clustered), which affects standard
*                         errors.
*   - [pweight=weight] -> declares `weight` as the probability weight to
*                         apply to every observation.
*   - strata(region)   -> tells Stata that `region` defines the STRATA:
*                         the population was divided into these groups
*                         before sampling, and sampling happened
*                         independently within each stratum.
svydescribe     // summarizes the design just declared: strata, PSUs, obs per stratum


* -----------------------------------------------------------------------
* 4. WEIGHTED VS. UNWEIGHTED: SIDE-BY-SIDE COMPARISON
*    Once `svyset` has run, prefix any supported command with `svy:` to
*    get design-based (weighted, clustered) estimates. Comparing these
*    side by side with the plain unweighted commands from Lessons 01-04
*    shows you exactly what weighting changes.
* -----------------------------------------------------------------------

* --- Categorical outcome: policy_support ---
tabulate policy_support             // UNWEIGHTED distribution (every respondent counts equally)
svy: tabulate policy_support        // WEIGHTED distribution (each respondent counts per their weight)
* Compare the percentages in each row. If, say, oversampled subgroups
* tended to answer differently, the weighted percentages will shift
* toward what the full population actually looks like.

* --- Continuous outcome: satisfaction ---
summarize satisfaction              // UNWEIGHTED mean and SD
svy: mean satisfaction              // WEIGHTED mean, with design-based standard error and CI
* svy: mean's output reports the weighted point estimate plus a
* linearized standard error and 95% CI that account for both the
* weighting and the clustering/stratification declared in svyset.


* -----------------------------------------------------------------------
* 5. THREE COMMON MISTAKES TO AVOID
*
*    (a) FORGETTING THE `svy:` PREFIX AFTER SVYSET.
*        Running `svyset ...` does NOT change how ordinary commands like
*        `tabulate` or `summarize` behave — those commands still ignore
*        weights and design entirely unless you put `svy:` in front of
*        them. `svyset` only registers the design; `svy:` is what
*        actually applies it.
*
*    (b) APPLYING SURVEY WEIGHTS TO DATA THAT ARE ALREADY AGGREGATED
*        (e.g., already `collapse`-d into group means or totals).
*        `svyset`/`svy:` expect one row per sampled unit (e.g., one row
*        per respondent). If your data have already been collapsed to,
*        say, one row per region with a mean already computed, applying
*        pweight/svyset again would double-count the weighting that's
*        already implicitly baked into those aggregates, and the
*        variance estimates would no longer make sense.
*
*    (c) CONFUSING FREQUENCY WEIGHTS WITH PROBABILITY WEIGHTS.
*        An fweight says "this row literally represents N identical
*        copies of this observation" (a count). A pweight says "this row
*        represents 1/p population members, where p was this row's
*        selection probability" (an inverse probability). Using fweight
*        syntax with what is really a pweight-style survey weight (or
*        vice versa) will run without an error, but the resulting
*        standard errors and even some point estimates will be wrong.
* -----------------------------------------------------------------------
di as txt "Remember: svyset registers the design; svy: is what applies it."


* ============ YOUR TURN ============
* 1. Using the design already declared above (no need to re-run svyset),
*    compute the WEIGHTED mean of satisfaction:
*
*    svy: mean satisfaction
*
* 2. Compute the UNWEIGHTED mean of satisfaction for comparison:
*
*    summarize satisfaction
*
* 3. In a comment below, note:
*      - Are the weighted and unweighted means noticeably different?
*      - If they differ, what would that imply about which kinds of
*        respondents (e.g., which region, or high/low weight) are
*        pulling the weighted estimate up or down relative to the
*        unweighted one?
*      - If they are similar, what would that suggest about whether
*        weighting matters much for this particular variable?

* Your comparison and explanation (as a comment):
* __________
