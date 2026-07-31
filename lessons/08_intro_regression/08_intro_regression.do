/*==============================================================================
LESSON 08 — INTRODUCTION TO REGRESSION
Lesson 8 of 14 — Stata Curriculum for Survey Researchers

PREREQUISITES:
    - Lesson 01 (importing/inspecting data)
    - Lesson 02 (cleaning and value labels) — this lesson uses the cleaned
      dataset produced there, data/survey_clean.dta
    - Lessons 04-07 (tabulate, confidence intervals, weighting basics,
      row/column percentages, crosstabs and tests). You do NOT need any
      prior regression experience for this lesson.

LEARNING OBJECTIVES:
    - Fit a linear regression (`regress`) predicting a continuous outcome
      and read every column of the coefficient table
    - Understand why R-squared should not be over-interpreted in survey /
      social-science data
    - Use factor-variable notation (`i.varname`) and understand how Stata
      picks a base category
    - Get simple predicted values with `margins` after a regression
    - Fit a logistic regression two ways — `logit` (log-odds) and
      `logistic` (odds ratios) — and know when each display is easier to
      talk about
    - Interpret an odds ratio in plain English
    - Recognize `estat vif` as a basic multicollinearity check
    - Understand — explicitly — that everything in this lesson ignores the
      survey design (weights/clusters/strata) on purpose, as a stepping
      stone, and that Lesson 09 redoes these same models correctly

ESTIMATED TIME: 45 minutes

IMPORTANT NOTE ON SURVEY DESIGN:
    Every model in this lesson is fit WITHOUT `svy:` and WITHOUT weights,
    even though we know from Lesson 05 that this dataset has a pweight and
    a clustered/stratified design. That is deliberate. Regression syntax
    and interpretation are already a lot to absorb for a first pass, so we
    strip out the survey-design complexity here and add it back in
    Lesson 09. Do NOT report these unweighted numbers as your final
    results for a real survey analysis — use the `svy:` versions from
    Lesson 09 instead.
==============================================================================*/


* --- 0. Setup ---------------------------------------------------------------
clear all                                    // start with a clean slate
set more off                                 // don't pause output a screen at a time

use "../../data/survey_clean.dta", clear     // load the Lesson 02 cleaned dataset

describe                                     // quick reminder of what's in this file


* --- 1. A first linear regression: satisfaction on age, income, education ---

* `satisfaction` is our continuous outcome (0-10 life satisfaction). We'll
* predict it from age, household income (in $1,000s), and educational
* attainment. `i.educ_raw` tells Stata to treat educ_raw as a SET OF
* CATEGORIES (factor variable) rather than as if "5" were five times "1".
regress satisfaction age income_k i.educ_raw
* Reading this table:
*   - Coef.      the estimated change in satisfaction for a 1-unit increase
*                in that predictor (or, for i.educ_raw levels, the gap
*                relative to the omitted/base category), holding the other
*                predictors constant
*   - Std. Err.  the standard error of that coefficient estimate
*   - t          Coef. / Std. Err. — the test statistic for "coefficient = 0"
*   - P>|t|      the two-sided p-value for that t statistic
*   - [95% CI]   the 95% confidence interval for the coefficient
*   - R-squared  the share of variance in satisfaction explained by the
*                model — see the caution below

* NOTE ON i.educ_raw AND THE BASE CATEGORY:
* By default Stata's factor-variable notation omits the SMALLEST numeric
* value of the variable as the "base" (here, 1 = Less than high school) and
* reports every other category's coefficient as a contrast against that
* base. You'll see "1.educ_raw" absent from the table (it's the reference)
* and "2.educ_raw", "3.educ_raw", "4.educ_raw", "5.educ_raw" each showing
* the gap in predicted satisfaction relative to "Less than high school",
* holding age and income_k fixed. Use `fvset base` or `ib#.` prefix notation
* if you ever need a different reference category (not needed today).

* CAUTION ON R-SQUARED:
* In individual-level survey data, human behavior and attitudes are noisy,
* so it is completely normal for R-squared to be small (e.g. 0.05-0.15) even
* when the model contains real, statistically significant relationships. A
* small R-squared does NOT mean the model is "wrong" or useless — it means
* individual-level satisfaction has a lot of variation this model doesn't
* capture. Don't chase a high R-squared by throwing in variables; focus on
* whether the coefficients are substantively and statistically meaningful.


* --- 2. A quick look at predicted values with margins -----------------------

* `margins` computes model-predicted values. Here we ask for the average
* predicted satisfaction score at each level of educ_raw, holding everything
* else in the model at each observation's own values (the default,
* "predictive margins"). This is often easier for an audience to digest than
* raw coefficients.
margins educ_raw
* You'll see one predicted satisfaction score per education category, each
* with its own SE and CI — useful for a simple bar chart or table in a memo.
* (marginsplot, not covered here, can turn this directly into a graph.)


* --- 3. A beginner-level multicollinearity check -----------------------------

* `estat vif` (variance inflation factor) is available immediately after
* `regress` and flags predictors that are so highly correlated with each
* other that their individual coefficients become unstable/hard to trust.
* Rule of thumb many analysts use: VIF above ~10 (some use a stricter cutoff
* of 5) deserves a closer look. This is not a full diagnostics lesson — just
* know this command exists and what the number roughly means.
estat vif


* --- 4. A binary outcome: logit (log-odds) ----------------------------------

* `voted_last_election` is 0/1. Ordinary `regress` is the wrong tool for a
* binary outcome (predictions aren't bounded between 0 and 1, and the
* standard errors are wrong). `logit` fits a logistic regression and reports
* coefficients on the LOG-ODDS scale.
logit voted_last_election age i.educ_raw
* Log-odds coefficients are hard to talk about in plain English (few people
* have intuition for "log-odds"), but this display is useful when you need
* to do further algebra with the coefficients (e.g. computing your own
* predicted probabilities by hand) or when a reviewer specifically expects
* log-odds output.


* --- 5. The same binary model, shown as odds ratios -------------------------

* `logistic` fits the EXACT SAME MODEL as `logit` — same coefficients,
* same standard errors, same p-values, same log-likelihood — it just
* exponentiates the coefficients for display, so you get ODDS RATIOS
* instead of log-odds. Use whichever display format is easier for your
* audience; the underlying model is identical.
logistic voted_last_election age i.educ_raw
* INTERPRETING AN ODDS RATIO IN PLAIN ENGLISH:
* An odds ratio of 1.00 means no association. An odds ratio ABOVE 1 means
* higher odds of the outcome (voting) as the predictor increases (or, for a
* factor level, relative to the base category); an odds ratio BELOW 1 means
* lower odds. For example, if 4.educ_raw (Bachelor's degree) shows an odds
* ratio of 1.8 relative to the base category (less than high school), you
* would say: "Holding age constant, respondents with a bachelor's degree
* have about 1.8 times the odds of having voted, compared to respondents
* with less than a high school education." Note this is a statement about
* ODDS, not probability — the two move together but are not the same
* number, and the difference matters more as probabilities move away from
* 50%.


* ============ YOUR TURN ============
* Pick EITHER the `regress` model in Section 1 OR the `logit`/`logistic`
* model in Section 4. Add ONE more predictor from the dataset (for example,
* female, or one of the trust_* variables) to that model's command, re-run
* it, and then write a comment below your command interpreting the new
* predictor's coefficient in plain English (remember: log-odds vs. odds
* ratio depends on whether you used `logit` or `logistic`).
*
* Example skeleton (fill in your own predictor and interpretation):
*
* regress satisfaction age income_k i.educ_raw female
* // interpretation: ...
*
* logistic voted_last_election age i.educ_raw female
* // interpretation: ...
