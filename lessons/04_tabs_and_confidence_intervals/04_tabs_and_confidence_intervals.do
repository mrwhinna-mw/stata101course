/*==============================================================================
    LESSON 04 — BASIC TABULATIONS & CONFIDENCE INTERVALS
    Lesson 04 of 14 — Stata Curriculum for Survey Researchers

    PREREQUISITES
      - Lessons 00-03 completed.
      - data/survey_clean.dta exists (produced by Lesson 02).
      - This lesson is UNWEIGHTED. Survey weighting is introduced in
        Lesson 05 and applied throughout everything from that point on.

    LEARNING OBJECTIVES
      By the end of this lesson you will be able to:
      - Produce one-way and two-way tabulations with `tabulate`, including
        how to handle missing values with the `missing` option.
      - Estimate a proportion and its confidence interval with `proportion`
        and with `ci proportions`.
      - State, in plain language, what a 95% confidence interval does and
        does not mean.
      - Explain how sample size affects the width of a confidence interval.

    ESTIMATED TIME: ~40 minutes

    A NOTE ON FILE PATHS
      This do-file lives in lessons/04_tabs_and_confidence_intervals/. The
      data lives in data/, two levels up. Hence "../../data/...".
==============================================================================*/

version 18
clear all
set more off

use "../../data/survey_clean.dta", clear   // canonical cleaned dataset; unweighted for this lesson


* -----------------------------------------------------------------------
* 1. ONE-WAY TABULATIONS
*    `tabulate varname` counts observations in each category and reports
*    both raw frequencies and percentages of the NON-MISSING total.
* -----------------------------------------------------------------------
tabulate policy_support             // distribution of the 4-category policy_support outcome

* By default, tabulate silently DROPS missing values from the table and
* from the percentage base. That can hide how much data is actually
* missing. The `missing` option shows missing as its own category:
tabulate policy_support, missing    // same table, but with "." shown as a row


* -----------------------------------------------------------------------
* 2. TWO-WAY TABULATIONS
*    Adding a second variable produces a cross-tabulation: rows are the
*    first variable, columns are the second.
* -----------------------------------------------------------------------
tabulate policy_support female       // does policy support differ by sex? (raw cell counts only, for now)
* Note: this shows only counts. Row/column/cell percentages are covered
* in Lesson 06 — for today we just want the mechanics of cross-tabbing.


* -----------------------------------------------------------------------
* 3. ESTIMATING A PROPORTION
*    `proportion varname` estimates the proportion of observations in
*    each category of a variable, along with a confidence interval for
*    each proportion, directly in its output table (no extra command
*    needed to see the CI — it is part of proportion's native output).
* -----------------------------------------------------------------------
proportion voted_last_election      // proportion who voted (0) vs. did not vote is coded 0/1, so two rows appear
* The output table has columns: Proportion, Std. Err., [95% Conf. Interval]
* Read the row labeled "1" for the proportion who voted, along with its CI.


* -----------------------------------------------------------------------
* 4. A DEDICATED COMMAND FOR SIMPLE BINOMIAL CIs
*    `ci proportions varname` is a more direct route when you only care
*    about a single binary variable's proportion and CI (it wraps a
*    binomial/Wald-type confidence interval calculation).
* -----------------------------------------------------------------------
ci proportions voted_last_election  // simple binomial CI for the voting rate
* Illustrative output structure (values will differ once real data exist):
*     Variable |        N     Mean   Std. Err.     [95% Conf. Interval]
*   -----------+---------------------------------------------------------
*   voted_last_|     1200     .58      .0142          .552        .607
*     election |
* (The exact numbers above are illustrative placeholders, not real output.)


* -----------------------------------------------------------------------
* 5. WHAT A 95% CONFIDENCE INTERVAL ACTUALLY MEANS
*    A very common misreading: "there is a 95% chance the true population
*    value falls in this interval." That is NOT correct in the standard
*    frequentist framework Stata uses here.
*
*    Correct interpretation: the true population proportion is a FIXED
*    (if unknown) number — it does not move around. What is random is
*    the SAMPLE we happened to draw. If we repeated this survey process
*    many times, drawing a new sample each time and building a 95% CI
*    the same way every time, approximately 95% of those intervals would
*    contain the true population value. For any ONE interval we compute
*    (like the single interval above), the true value either is or is
*    not inside it — we just don't know which, and 95% is our long-run
*    confidence in the PROCEDURE, not a probability statement about this
*    particular interval.
* -----------------------------------------------------------------------
di as txt "A 95% CI means: if we repeated the survey many times, about"
di as txt "95% of the intervals we'd build this way would contain the"
di as txt "true population value. It is NOT a 95% chance for this one interval."


* -----------------------------------------------------------------------
* 6. HOW SAMPLE SIZE DRIVES CI WIDTH
*    Confidence interval width is driven largely by standard error, and
*    standard error shrinks as sample size (N) grows — roughly in
*    proportion to 1/sqrt(N). So quadrupling your sample only halves
*    your margin of error, not eliminates it.
*    Compare the width of a CI on the full sample vs. a small subgroup:
* -----------------------------------------------------------------------
ci proportions voted_last_election                       // full sample: ~1,200 obs, narrower CI
ci proportions voted_last_election if region == 1         // Northeast only: fewer obs, expect a WIDER CI
* Look at the two "[95% Conf. Interval]" columns above and compare their
* widths (upper bound minus lower bound). The subgroup interval should be
* noticeably wider because it is based on far fewer observations — this
* is the practical meaning of "margin of error" you'll see reported next
* to poll results in the news.


* ============ YOUR TURN ============
* 1. Create a new binary variable indicating whether a respondent has a
*    college degree or more, based on educ_raw (recall from Lesson 02's
*    schema: 4 = Bachelor's degree, 5 = Graduate degree).
*
*    gen college = (educ_raw >= 4) if !missing(educ_raw)
*    label define college_lbl 0 "No college degree" 1 "College degree or more"
*    label values college college_lbl
*
* 2. Tabulate it to sanity-check the recode:
*
*    tabulate college, missing
*
* 3. Compute its proportion and 95% CI:
*
*    ci proportions college
*
* 4. In a comment below, write one sentence interpreting the CI correctly
*    (not "95% chance the true value is in this range").

* Your interpretation (as a comment):
* __________
