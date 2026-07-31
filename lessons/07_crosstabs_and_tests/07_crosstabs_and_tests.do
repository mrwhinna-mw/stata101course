/*==============================================================================
LESSON 07 — CROSSTABS WITH STATISTICAL TESTS
Lesson 7 of 14 — Stata Curriculum for Survey Researchers

PREREQUISITES:
    - Lesson 02 (cleaning and labels) — this lesson uses data/survey_clean.dta
    - Lesson 04 (tabs and confidence intervals)
    - Lesson 05 (weighting basics) — `svyset`, pweights
    - Lesson 06 (row vs. column percentages)

LEARNING OBJECTIVES:
    - Add a Pearson chi-squared test of independence to a tabulation with
      `tabulate ..., chi2`
    - Add Fisher's exact test with `tabulate ..., chi2 exact`, and know when
      small expected cell counts make the exact test the more trustworthy one
    - Contrast a naive (unweighted, non-design) chi-squared test with the
      design-based equivalent `svy: tabulate ..., pearson`
    - Explain WHY ignoring clustering and weighting in a complex survey
      design can make a test look more significant than it should
    - Recognize that with large survey samples, statistical significance
      does not imply a substantively large or important association
    - Read a chi-square result alongside column percentages, and know what
      Cramer's V adds as an effect-size companion

ESTIMATED TIME: 35 minutes
==============================================================================*/


* --- 0. Setup ----------------------------------------------------------------
clear   // start clean

use "../../data/survey_clean.dta", clear   // load the canonical cleaned dataset from Lesson 02

svyset psu [pweight=weight], strata(region)   // declare the complex survey design taught in Lesson 05: psu = cluster, weight = pweight, region = strata

describe female voted_last_election   // confirm the two binary variables we'll test first are in memory with their value labels


* --- 1. The naive (unweighted, non-design) chi-squared test -------------------
* `tabulate ..., chi2` reports Pearson's chi-squared test of independence,
* treating every row of data as if it were an independent simple random
* draw. It completely ignores that `weight` exists and that respondents are
* clustered in `psu`.
tabulate female voted_last_election, chi2   // naive Pearson chi2: tests H0 "female and voted_last_election are independent," assuming simple random sampling

* Read the Pearson chi2 statistic, its degrees of freedom, and the p-value
* (labeled Pr) in the output. A small p-value (conventionally < 0.05) leads
* us to reject the independence assumption — but keep reading before you
* trust that p-value at face value for survey data.


* --- 2. Fisher's exact test: `chi2 exact` --------------------------------------
* The Pearson chi-squared test is only an approximation, and that
* approximation degrades when expected cell counts are small (a common
* rule of thumb: any expected cell count below 5). Fisher's exact test
* computes an exact p-value instead of relying on the large-sample chi2
* approximation, so it is the safer choice whenever your table has thin
* cells — which is common once you cross a rare category (e.g., a small
* region, or a rarely-chosen policy_support level) with another variable.
tabulate female voted_last_election, chi2 exact   // adds Fisher's exact p-value alongside the Pearson chi2; trust the exact p-value over the Pearson one whenever expected cell counts are small

* female x voted_last_election are both common, roughly balanced binary
* variables, so expected cell counts here are almost certainly large and
* the exact and asymptotic p-values should be very close. The exact test
* earns its keep on THINNER tables — for example, crossing region (4
* categories) with a policy_support category that few respondents choose.
tabulate region policy_support, chi2 exact   // a table with more cells and likely some small counts is exactly where `exact` starts to matter


* --- 3. Why the naive test can mislead with survey data ------------------------
* The naive chi-squared test above assumes every one of your ~1,200 rows is
* an independent simple random draw from the population. Real survey data
* from a complex design violate that assumption in two specific ways:
*
*   (a) CLUSTERING: respondents in the same `psu` (cluster) tend to be more
*       similar to each other than two randomly chosen respondents from
*       different clusters would be. That similarity means each additional
*       respondent within a cluster carries LESS new independent
*       information than the naive test assumes. Ignoring clustering
*       overstates your effective sample size, which shrinks standard
*       errors and INFLATES the chi-squared statistic — making
*       associations look more statistically significant than they truly
*       are.
*   (b) WEIGHTING: `weight` corrects for unequal probabilities of selection
*       across strata/PSUs. A naive `tabulate` ignores it entirely and
*       just counts raw rows, which can both bias the estimated
*       association and, again, misstate how much genuine information the
*       sample contains.
*
* Both problems point the same direction: a naive Pearson chi2 on
* unweighted, non-svyset survey data tends to overstate significance
* (p-values look smaller / more impressive than they should).


* --- 4. The design-based alternative: `svy: tabulate ..., pearson` -------------
* Once the survey design is `svyset`, prefix the SAME tabulation with `svy:`
* and request `pearson` to get a design-based test that accounts for both
* clustering and weighting.
svy: tabulate female voted_last_election, pearson   // design-based test: an F-adjusted version of the Pearson chi2 statistic, computed to respect psu clustering, region strata, and pweights

* `svy: tabulate ..., pearson` reports an F statistic (with numerator and
* denominator degrees of freedom adjusted for the design), NOT a raw
* chi-squared statistic — this is often called the second-order
* Rao-Scott-type correction in the survey literature, and it is what
* StataCorp's own [SVY] Survey Data manual recommends over naive chi2 for
* tabulations of svyset data. Compare its p-value to the naive test's
* p-value in Section 1: if the design-based p-value is noticeably larger
* (less significant), that is the clustering/weighting correction doing
* its job — the naive test was likely overstating how confident you should
* be in the association.
*
* NOTE: `svy: tabulate` does not support the `exact` option — the
* design-based framework is inherently large-sample (Wald/F-based), so
* there is no design-based analogue to Fisher's exact test in this
* command.


* --- 5. Statistical significance vs. substantive size ---------------------------
* With ~1,200 respondents (or more, in many real surveys), even a very
* small, practically unimportant association between two variables can
* still produce a "significant" chi-squared p-value. Significance tells
* you only that an association is unlikely to be pure noise — it says
* NOTHING about how big or policy-relevant that association is. Always
* pair a significance test with a look at the actual percentages and, when
* possible, a standardized effect size.
tabulate female voted_last_election, column chi2   // combine: read the column percentages (from Lesson 06) alongside the chi2 test to judge BOTH significance and substantive size in one table

* Reading the combined output: the chi2 p-value tells you whether female
* and voted_last_election are related at all; the column percentages tell
* you HOW DIFFERENT the voting rate is between men and women. A p-value of
* 0.001 attached to a 2-percentage-point gap between men and women is
* statistically real but may be substantively negligible for most research
* or policy purposes; always report both together, never the p-value alone.
*
* For a standardized effect-size measure for two-way tables, `tabulate`
* itself has a built-in `V` option that reports Cramer's V directly below
* the table — a chi-squared-based measure rescaled to fall between 0 (no
* association) and 1 (perfect association), which makes it comparable
* across tables of different sizes (unlike the raw chi2 statistic, whose
* magnitude depends on sample size and table dimensions).
tabulate female voted_last_election, chi2 V   // adds Cramer's V beneath the chi2 result: the effect-size companion to the significance test

* Cramer's V is the effect-size companion to the chi2 test's significance:
* use chi2 (or the svy F-test) to ask "is there evidence of an association
* at all," and Cramer's V to ask "how strong is that association." A tiny
* Cramer's V (say, well under 0.1) alongside a "significant" chi2 is the
* classic large-sample-survey pattern: real, but substantively small.


* ============ YOUR TURN ============
* Choose TWO other categorical variables from survey_clean.dta (for
* example: region and educ_raw, or trust_gov and voted_last_election).
* For your chosen pair:
*
*   1. Run the NAIVE (non-svy) chi-squared test:
*        tabulate ___ ___, chi2
*
*   2. Run the design-based test:
*        svy: tabulate ___ ___, pearson
*
*   3. In a comment, compare the two p-values. Did accounting for the
*      survey design (clustering + weighting) change your conclusion about
*      whether the two variables are related? Would you have reported a
*      different substantive finding if you had only run the naive test?
*
* tabulate ___ ___, chi2
*
* svy: tabulate ___ ___, pearson
*
* * Your comparison and conclusion here:
