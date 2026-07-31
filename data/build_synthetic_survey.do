/*==============================================================================
BUILD_SYNTHETIC_SURVEY.DO

PURPOSE:
    Generates the single synthetic survey dataset used across every lesson in
    this curriculum. It is meant to feel like a plausible general-population
    attitudes survey: demographics, a few Likert/ordinal opinion items, a
    binary outcome, a continuous outcome, survey design variables (weight,
    strata, PSU), and some deliberately messy raw fields so Lessons 01-02 have
    real cleaning work to do.

    You do NOT need to run this file as a learner. It is provided so you can
    see exactly how the data were generated (full transparency, nothing is a
    "black box"), and so the dataset can be regenerated if it's ever lost.
    Instructors: run this once to produce data/survey_raw.csv, which is what
    Lesson 01 starts from.

REQUIREMENTS:
    Stata 18. No community-contributed packages needed for this file.

OUTPUT:
    data/survey_raw.csv   <- messy version, used starting in Lesson 01
    (survey_clean.dta is NOT created here - learners build it themselves in
    Lesson 02, that's the point of the exercise)
==============================================================================*/

clear all
set more off
version 18

* Fixed seed so everyone who runs this gets byte-for-byte identical data.
set seed 20260401

* -----------------------------------------------------------------------
* 1. Set the sample size and create the skeleton of respondent IDs
* -----------------------------------------------------------------------
local n_obs = 1200
set obs `n_obs'

gen respondent_id = _n
label variable respondent_id "Unique respondent identifier"

* -----------------------------------------------------------------------
* 2. Survey design variables: strata, PSU (primary sampling unit), weight
*    Simulates a stratified, clustered design like many real household
*    surveys (e.g., strata = region, psu = sampled neighborhood/cluster)
* -----------------------------------------------------------------------
gen region = ceil(runiform() * 4)
label define region_lbl 1 "Northeast" 2 "South" 3 "Midwest" 4 "West"
label values region region_lbl
label variable region "Census region (survey stratum)"

* 30 PSUs nested within regions, ~40 respondents per PSU on average
gen psu = ceil(runiform() * 30)
label variable psu "Primary sampling unit (survey cluster)"

* Base weight inversely related to region size, plus noise, so weighted and
* unweighted estimates will visibly differ later (that's the pedagogical point)
gen double base_weight = cond(region == 1, 1.35, ///
                          cond(region == 2, 0.85, ///
                          cond(region == 3, 1.10, 0.75)))
gen double weight = base_weight * rnormal(1, 0.15)
replace weight = 0.2 if weight < 0.2
label variable weight "Survey (post-stratification) weight"

* -----------------------------------------------------------------------
* 3. Demographics
* -----------------------------------------------------------------------
gen age = round(rnormal(46, 16))
replace age = 18 if age < 18
replace age = 90 if age > 90
label variable age "Respondent age in years"

gen female = (runiform() < 0.51)
label define female_lbl 0 "Male" 1 "Female"
label values female female_lbl
label variable female "Respondent sex"

* Education, ordinal 1-5
gen educ_raw = 1 + rbinomial(4, 0.45)
label define educ_lbl 1 "Less than high school" 2 "High school graduate" ///
    3 "Some college" 4 "Bachelor's degree" 5 "Graduate degree"
label values educ_raw educ_lbl
label variable educ_raw "Educational attainment"

* Household income, continuous-ish (in $1,000s), right-skewed like real income
gen double income_k = exp(rnormal(3.55, 0.55))
replace income_k = round(income_k, 0.1)
label variable income_k "Household income ($1,000s)"

* -----------------------------------------------------------------------
* 4. Attitude / Likert items (5-point agreement scales) - these are the
*    ordinal indicators used later for dominance analysis and latent class
*    analysis, so keep this block consistent if you ever regenerate.
*    Built from a single latent "institutional trust" factor + noise so
*    they are correlated in a realistic, recoverable way for Lesson 12.
* -----------------------------------------------------------------------
gen double trust_factor = rnormal(0, 1)

* trust_gov, trust_media, trust_science, trust_local: 1=Strongly disagree ... 5=Strongly agree
foreach v in trust_gov trust_media trust_science trust_local {
    tempvar raw
    gen double `raw' = trust_factor + rnormal(0, 0.9)
    gen `v' = 1
    replace `v' = 2 if `raw' > -0.9
    replace `v' = 3 if `raw' > -0.3
    replace `v' = 4 if `raw' > 0.3
    replace `v' = 5 if `raw' > 0.9
}
label define agree5_lbl 1 "Strongly disagree" 2 "Disagree" 3 "Neither agree nor disagree" ///
    4 "Agree" 5 "Strongly agree"
label values trust_gov trust_media trust_science trust_local agree5_lbl
label variable trust_gov   "Trust: national government generally acts in people's interest"
label variable trust_media "Trust: news media report accurately"
label variable trust_science "Trust: scientific institutions"
label variable trust_local  "Trust: local government"

* Overall policy support item, ordinal 1-4, used in Lessons 10-11 as the
* dominance-analysis outcome (depends on the trust items + education + age)
gen double support_index = 0.5*trust_gov + 0.3*trust_science - 0.15*(age/50) ///
    + 0.2*(educ_raw/3) + rnormal(0, 1)
gen policy_support = 1
replace policy_support = 2 if support_index > -0.4
replace policy_support = 3 if support_index > 0.5
replace policy_support = 4 if support_index > 1.3
label define support_lbl 1 "Strongly oppose" 2 "Somewhat oppose" ///
    3 "Somewhat support" 4 "Strongly support"
label values policy_support support_lbl
label variable policy_support "Support for the proposed community policy (ordinal outcome)"

* -----------------------------------------------------------------------
* 5. Binary and continuous outcomes for the regression lessons
* -----------------------------------------------------------------------
* Turnout: binary outcome for logit lessons, depends on age + education
gen double turnout_index = -2.2 + 0.03*age + 0.35*educ_raw + rnormal(0, 1)
gen voted_last_election = (turnout_index > 0)
label define yesno_lbl 0 "No" 1 "Yes"
label values voted_last_election yesno_lbl
label variable voted_last_election "Voted in the last local election"

* Life satisfaction: continuous (0-10) outcome for OLS lessons
gen double satisfaction = 5 + 0.4*trust_local + 0.15*(income_k/50) ///
    - 0.01*(age-46) + rnormal(0, 1.2)
replace satisfaction = 0 if satisfaction < 0
replace satisfaction = 10 if satisfaction > 10
replace satisfaction = round(satisfaction, 0.1)
label variable satisfaction "Life satisfaction (0=worst possible, 10=best possible)"

drop trust_factor support_index turnout_index

* -----------------------------------------------------------------------
* 6. Deliberately mess things up so Lessons 01-02 have real work to do.
*    This block simulates common real-world survey export problems.
* -----------------------------------------------------------------------
preserve

* (a) Recode some numeric variables to string with stray text, as if
*     exported from an online survey tool
tostring age, replace
replace age = "REFUSED" if runiform() < 0.02

tostring income_k, replace force
replace income_k = "N/A" if runiform() < 0.03
replace income_k = "" if runiform() < 0.02

* (b) Introduce a "don't know" numeric missing-value code (common in survey
*     data) on the trust items instead of a clean Stata missing value
foreach v in trust_gov trust_media trust_science trust_local {
    quietly replace `v' = -99 if runiform() < 0.04
}

* (c) Duplicate a handful of rows, as if the export process double-counted
*     a batch of paper questionnaires
expand 2 if inlist(respondent_id, 15, 274, 611, 900), gen(_dup_flag)
drop _dup_flag

* (d) Inconsistent capitalization / stray whitespace in the region string
*     version used only in the raw export (kept separate from the labeled
*     numeric `region` so Lesson 01 has a string variable to clean)
gen region_str = ""
replace region_str = " northeast" if region == 1
replace region_str = "SOUTH"      if region == 2
replace region_str = "Midwest "   if region == 3
replace region_str = "west"       if region == 4
drop region

* (e) Shuffle column order the way a raw export often does, and export
order respondent_id region_str psu weight age female educ_raw income_k ///
    trust_gov trust_media trust_science trust_local policy_support ///
    voted_last_election satisfaction

export delimited using "survey_raw.csv", replace

restore

* survey_raw.csv is the deliverable of this file. The in-memory clean
* version above is discarded on purpose - Lesson 02 is where learners
* build survey_clean.dta themselves from survey_raw.csv.
di as result "Done. Wrote survey_raw.csv with `n_obs' base respondents (plus a few intentional duplicates)."
