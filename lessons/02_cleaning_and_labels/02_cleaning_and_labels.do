/*==============================================================================
LESSON 02 — DATA CLEANING & LABELING
Lesson 2 of 14 — Stata Curriculum for Survey Researchers

PREREQUISITES:
    Lesson 00 (Setup & Orientation)
    Lesson 01 (Importing Data & First Look) — we clean exactly the issues
    Lesson 01 identified: string age/income_k, -99 codes, messy region_str,
    and duplicate rows.

LEARNING OBJECTIVES:
    - Convert string numeric variables to true numeric with `destring`,
      correctly turning known non-numeric codes (e.g. "REFUSED", "N/A")
      into proper Stata missing values via the `force` option, and verify
      that `force` did not silently discard anything unexpected
    - Recode an out-of-range "don't know" numeric code (-99) to true
      Stata missing on multiple variables
    - Clean an inconsistent string variable (stray case/whitespace) into a
      labeled numeric categorical variable using `encode`
    - Find and remove exact duplicate rows with `duplicates report` /
      `duplicates drop`
    - Apply `label variable` and `label define` / `label values` to every
      variable so the dataset is self-documenting
    - Save a single canonical analysis file, data/survey_clean.dta, that
      every later lesson in this curriculum will `use`

ESTIMATED TIME: 40 minutes

NOTE: This do-file assumes Stata is run from this lesson's folder
      (lessons/02_cleaning_and_labels/); adjust the `cd` line below if your
      own folder layout differs. The data file is one level up in
      ../../data/ relative to this lesson's folder, and that is where the
      cleaned output is written too. EVERY LATER LESSON in this curriculum
      uses this same relative-path convention (do-files in lessons/NN_x/,
      data in ../../data/) — keep it consistent as you go.
==============================================================================*/

capture log close
clear

* cd "lessons/02_cleaning_and_labels"   // uncomment/edit if Stata did not already start here

* We start over from the RAW file, exactly like Lesson 01 did. We are not
* building on any in-memory state left over from Lesson 01 (there wasn't
* any saved anyway) — this keeps this do-file fully self-contained and
* re-runnable on its own.
import delimited "../../data/survey_raw.csv", varnames(1) case(preserve) clear


* --- 1. Destring age: turn "REFUSED" into proper missing --------------------
codebook age   // BEFORE picture: confirm age is currently str* and note how many distinct values/observations exist, so we can compare after destring

* `destring` converts a string variable that looks numeric into a real
* numeric variable. Plain `destring` refuses to run if it finds ANY value
* that cannot be converted to a number — which is exactly what we want by
* default, since a silent conversion could hide a real data problem. Here
* we already know from Lesson 01 that "REFUSED" is the only non-numeric
* text in this column, so we deliberately override that safety check with
* `force`, which converts everything convertible and turns anything else
* (here, "REFUSED") into standard Stata missing (.).
destring age, replace force

* Never use `force` blindly. Always follow it with a check that the ONLY
* values that became missing are the ones you expected.
count if missing(age)   // should match the number of "REFUSED" rows we saw in Lesson 01 (34 in this dataset)
codebook age   // AFTER picture: age should now show as a numeric type (int/float) with a sensible min/max (e.g., roughly 18-90) and the missing count noted above


* --- 2. Destring income_k: turn "N/A" and blank into proper missing ---------
codebook income_k   // BEFORE picture

* Same logic as age: we know from Lesson 01 that the only non-numeric
* entries are "N/A" and empty strings, so `force` is again the right tool,
* used with the same follow-up caution.
destring income_k, replace force

count if missing(income_k)   // should match the combined count of "N/A" and blank income_k rows from Lesson 01
codebook income_k   // AFTER picture: income_k should now be a numeric (float/double) variable, right-skewed, with the missing count above and no impossible values (e.g., no negative income)


* --- 3. Recoding the -99 "don't know" code to true missing ------------------
* -99 is not a real Stata missing value yet — it is just a normal-looking
* number that happens to fall outside the valid 1-5 Likert range. If we
* left it alone, `summarize trust_gov` would compute a mean pulled sharply
* downward by a handful of -99s, which would be silently wrong. We use
* explicit `replace ... if` statements (rather than `mvdecode`) because it
* keeps the recoding rule fully visible right here in the do-file for
* anyone reading it later — you will also see `mvdecode` used for the same
* purpose elsewhere in Stata documentation; either approach is acceptable,
* but `replace` makes the exact condition unmistakable at a glance.
foreach v of varlist trust_gov trust_media trust_science trust_local {
    replace `v' = . if `v' == -99   // set true Stata missing (.) wherever the legacy "don't know" code appears
}

tab1 trust_gov trust_media trust_science trust_local, missing   // confirm each variable's range is now a clean 1-5 with an explicit missing category, and no -99 remains


* --- 4. Cleaning region_str into a labeled numeric region variable ----------
tab region_str   // reminder of the mess: " northeast", "SOUTH", "Midwest ", "west" as four separate string categories that should really be four consistent groups

* First, standardize the text itself: `strtrim` removes leading/trailing
* whitespace, and `proper()` converts to Title Case (e.g. "south" ->
* "South"), which also has the side effect of neutralizing case
* differences like "SOUTH" vs "south".
replace region_str = strtrim(region_str)   // drop the stray leading/trailing spaces we saw on " northeast" and "Midwest "
replace region_str = proper(region_str)    // fold case so "SOUTH" and "west" match the same Title Case pattern as the others

tab region_str   // confirm we are now down to exactly four clean categories: Northeast, South, Midwest, West

* `encode` is the idiomatic Stata way to turn a clean string variable into
* a numeric categorical variable: it automatically creates a new numeric
* variable, builds a value label from the distinct string values (in
* alphabetical order by default), and attaches that label — all in one
* step. We ask for the underlying category order to be assigned via
* `label()` afterward instead, because policy convention in this
* curriculum (and common survey-report convention) presents regions in the
* order Northeast, South, Midwest, West rather than alphabetically.
encode region_str, generate(region)   // creates numeric `region` + a same-named value label built from the cleaned strings

* By default `encode` assigns codes in alphabetical order of the string
* values (Midwest=1, Northeast=2, South=3, West=4), which does not match
* the order used in this curriculum's documentation and in the original
* build script (Northeast=1, South=2, Midwest=3, West=4). We fix that
* explicitly so region codes are consistent with every later lesson.
label define region_lbl 1 "Northeast" 2 "South" 3 "Midwest" 4 "West", replace
* encode's alphabetical order gives us Midwest=1, Northeast=2, South=3, West=4;
* we want Northeast=1, South=2, Midwest=3, West=4, so remap accordingly:
recode region (1=3) (2=1) (3=2) (4=4), generate(region_fixed)   // Midwest 1->3, Northeast 2->1, South 3->2, West 4->4 (unchanged)
drop region
rename region_fixed region
label values region region_lbl
label variable region "Census region (survey stratum)"

tab region, missing   // final check: four clean categories, correct labels, no missing

drop region_str   // no longer needed once `region` is built; keeping both would invite someone to accidentally use the messy version later


* --- 5. Finding and dropping exact duplicate rows ---------------------------
duplicates report   // reports how many observations are exact duplicates of another row across ALL variables

duplicates report respondent_id   // narrower check: are any respondent_id values repeated? (there should be exactly 4: ids 15, 274, 611, 900, each appearing twice)

duplicates list respondent_id   // list out which respondent_id values are duplicated, so we can see them before removing anything

duplicates drop   // drops rows that are complete duplicates of an earlier row across every variable, keeping the first occurrence of each

count   // should now read 1,200 - back down from 1,204 after removing the 4 duplicate pairs found above


* --- 6. Variable and value labels for everything ----------------------------
* region, done above, already has both a variable label and value label.

label variable respondent_id "Unique respondent identifier"
label variable psu "Primary sampling unit (survey cluster)"
label variable weight "Survey (post-stratification) weight"
label variable age "Respondent age in years"
label variable income_k "Household income ($1,000s)"

label define female_lbl 0 "Male" 1 "Female"
label values female female_lbl
label variable female "Respondent sex"

label define educ_lbl 1 "Less than high school" 2 "High school graduate" ///
    3 "Some college" 4 "Bachelor's degree" 5 "Graduate degree"
label values educ_raw educ_lbl
label variable educ_raw "Educational attainment"

label define agree5_lbl 1 "Strongly disagree" 2 "Disagree" ///
    3 "Neither agree nor disagree" 4 "Agree" 5 "Strongly agree"
label values trust_gov trust_media trust_science trust_local agree5_lbl
label variable trust_gov    "Trust: national government generally acts in people's interest"
label variable trust_media  "Trust: news media report accurately"
label variable trust_science "Trust: scientific institutions"
label variable trust_local  "Trust: local government"

label define support_lbl 1 "Strongly oppose" 2 "Somewhat oppose" ///
    3 "Somewhat support" 4 "Strongly support"
label values policy_support support_lbl
label variable policy_support "Support for the proposed community policy (ordinal outcome)"

label define yesno_lbl 0 "No" 1 "Yes"
label values voted_last_election yesno_lbl
label variable voted_last_election "Voted in the last local election"

label variable satisfaction "Life satisfaction (0=worst possible, 10=best possible)"


* --- 7. Saving the canonical clean dataset -----------------------------------
* From this point on, EVERY other lesson in this curriculum begins with:
*     use "../../data/survey_clean.dta", clear
* so it is worth pausing here: this save step is the single most important
* line in this do-file.
save "../../data/survey_clean.dta", replace


* --- 8. Admiring the finished product ----------------------------------------
describe   // every variable should now show a sensible storage type and a variable label — compare against Lesson 01's `describe` output, where age/income_k were still strings and several labels were missing

codebook, compact   // one line per variable; scan for: no more str* types on age/income_k, no variable still showing -99 as a valid value, region showing exactly 4 categories, and 1,200 observations throughout


* ============ YOUR TURN ============
* Pick ONE of the following and complete it in a comment (or, for the
* first option, in actual code appended below):
*
*   (a) Edge case: after `destring income_k, replace force`, confirm for
*       yourself that EVERY observation now missing on income_k truly
*       corresponds to an original "N/A" or blank cell, and not some other
*       text you haven't accounted for. (Hint: you will need to re-import
*       and re-run only Sections 1-2 with a temporary variable to compare
*       against, since the original string values no longer exist in the
*       current dataset in memory.)
*
*   (b) Data quality memo: write a short (4-6 sentence) memo, as comments
*       below, addressed to a project lead who will use survey_clean.dta.
*       Summarize: how many observations were dropped and why, how many
*       values were set to missing on each of age/income_k/the four trust
*       items and why, and one thing a future analyst should watch out for
*       (e.g., missing income_k when using income in a regression).
*
* (write your answer here)
