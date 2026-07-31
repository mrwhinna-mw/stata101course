/*==============================================================================
LESSON 06 — ROW vs. COLUMN PERCENTAGES
Lesson 6 of 14 — Stata Curriculum for Survey Researchers

PREREQUISITES:
    - Lesson 01 (import and inspect)
    - Lesson 02 (cleaning and labels) — this lesson uses the cleaned dataset
      produced there, data/survey_clean.dta
    - Lesson 04 (tabs and confidence intervals) — basic `tabulate` syntax
    - Lesson 05 (weighting basics) — `svyset`, pweights

LEARNING OBJECTIVES:
    - Produce a two-way tabulation with `tabulate var1 var2`
    - Add row percentages with `, row`, column percentages with `, column`,
      and cell (grand-total) percentages with `, cell`
    - State precisely what denominator each percentage type uses
    - Translate a row percentage and a column percentage from the SAME table
      into two DIFFERENT plain-English research claims
    - Recognize and correct the single most common misreading of a two-way
      table: citing a column percent as though it were a row percent (or
      vice versa)

ESTIMATED TIME: 30 minutes
==============================================================================*/


* --- 0. Setup ----------------------------------------------------------------
clear   // start clean so nothing from a prior session lingers

use "../../data/survey_clean.dta", clear   // load the canonical cleaned dataset built in Lesson 02

* This lesson is about reading percentages correctly, not about weighting.
* We still declare the survey design because it is good habit to have it set
* whenever survey data are in memory, but the `tabulate ... , row/column/cell`
* commands below are UNWEIGHTED frequency crosstabs — they use the raw counts
* in the data, not svy-adjusted estimates. (Lesson 07 contrasts unweighted
* and design-based tabulations directly.)
svyset psu [pweight=weight], strata(region)   // declare the survey design (taught in Lesson 05); not used by plain `tabulate` but kept set as habit

describe educ_raw policy_support   // confirm both variables and their value labels are in memory before we tabulate them


* --- 1. The plain two-way table ----------------------------------------------
* `tabulate` with two variables cross-classifies every respondent by BOTH
* variables at once. Each cell shows a raw COUNT: the number of respondents
* who have that specific combination of educ_raw and policy_support.
tabulate educ_raw policy_support   // baseline: raw counts only, no percentages yet — always look at this first so you know your cell sizes before trusting any percentage

* Look at the cell sizes before you look at any percentage. A percentage
* built on a cell of 4 respondents can look dramatic and mean very little.


* --- 2. Row percentages: `, row` ---------------------------------------------
* Row percentages make each ROW sum to 100%. The denominator for every cell
* in a given row is the TOTAL NUMBER OF RESPONDENTS IN THAT ROW (i.e., the
* row's marginal total), regardless of how the columns are distributed.
tabulate educ_raw policy_support, row   // row % = (cell count) / (row total) * 100; each row of output sums to 100

* Row percentages answer questions of the form:
*   "AMONG people with [row category], what share fall into each
*    [column category]?"
* Worked example: with educ_raw as the row variable and policy_support as
* the column variable, the row-percent cell at
*   (educ_raw = 4 "Bachelor's degree", policy_support = 4 "Strongly support")
* answers: "Of people with a Bachelor's degree, what percentage strongly
* support the policy?" That is a statement ABOUT bachelor's-degree holders,
* restricted to that row, and it says nothing about how bachelor's-degree
* holders compare to the rest of the sample in absolute numbers.


* --- 3. Column percentages: `, column` ----------------------------------------
* Column percentages make each COLUMN sum to 100%. The denominator for every
* cell in a given column is the TOTAL NUMBER OF RESPONDENTS IN THAT COLUMN.
tabulate educ_raw policy_support, column   // col % = (cell count) / (column total) * 100; each column of output sums to 100

* Column percentages answer the MIRROR-IMAGE question:
*   "AMONG people with [column category], what share fall into each
*    [row category]?"
* Worked example, same table, same physical cell as above:
* the column-percent value at
*   (educ_raw = 4 "Bachelor's degree", policy_support = 4 "Strongly support")
* now answers: "Of people who strongly support the policy, what percentage
* have a Bachelor's degree?" That is a statement ABOUT strong supporters,
* restricted to that column — a completely different substantive claim from
* the row-percent version, even though it comes from the identical cell.


* --- 4. Cell percentages: `, cell` --------------------------------------------
* Cell percentages use ONE denominator for the entire table: the GRAND TOTAL
* of all respondents in the table (all rows, all columns combined). Every
* cell in the whole table sums to 100%, not just a row or a column.
tabulate educ_raw policy_support, cell   // cell % = (cell count) / (grand total) * 100; the ENTIRE table's cells sum to 100

* Cell percentages answer a THIRD kind of question:
*   "Out of EVERYONE surveyed, what share falls into this exact combination
*    of [row category] AND [column category]?"
* Worked example, same cell again: the cell percent at
*   (educ_raw = 4 "Bachelor's degree", policy_support = 4 "Strongly support")
* answers: "What percentage of the WHOLE sample is both a bachelor's-degree
* holder AND a strong supporter?" This is usually a smaller number than
* either the row or column percent, because its denominator (everyone) is
* the largest of the three.


* --- 5. All three at once -----------------------------------------------------
* You can request row, column, and cell percentages together in a single
* table for direct comparison. Each cell then reports four numbers: the raw
* count, then its row%, column%, and cell% versions side by side.
tabulate educ_raw policy_support, row column cell   // one table, three denominators, for side-by-side comparison of the SAME cells


* --- 6. Worked misinterpretation pitfall ---------------------------------------
* THE single most common mistake with two-way tables: reading a column
* percentage as if it were a row percentage (or vice versa), which silently
* FLIPS the substantive claim being made.
*
* Concretely: suppose the column-percent table above shows that, in the
* column for policy_support = 4 "Strongly support", 40% of that column's
* respondents have educ_raw = 4 "Bachelor's degree". A careless reader might
* write this up as:
*     "40% of Bachelor's-degree holders strongly support the policy."
* That sentence is actually describing the ROW-percent question — but the
* 40% we have in hand came from the COLUMN-percent table, where the
* denominator was "everyone who strongly supports," not "everyone with a
* Bachelor's degree." The correct reading of that same 40% is:
*     "Of people who strongly support the policy, 40% have a Bachelor's
*      degree."
* These are NOT the same claim, and they are not even guaranteed to be
* close in magnitude, because Bachelor's-degree holders and strong
* supporters are very different-sized groups in most populations (unequal
* row and column marginals). Before you write a sentence describing a
* percentage from a two-way table, always ask yourself: "which option did I
* request — row, column, or cell — and does my sentence's denominator match
* it?"


* --- 7. A second worked pair, side by side -------------------------------------
* To reinforce the point, here is the same educ_raw x policy_support table
* requested twice, once as row% and once as column%, so you can compare the
* identical cell across both denominators directly.
tabulate educ_raw policy_support, row nofreq   // row%, counts suppressed for a cleaner side-by-side read
tabulate educ_raw policy_support, column nofreq   // column%, counts suppressed — compare the (Bachelor's, Strongly support) cell in each table above


* ============ YOUR TURN ============
* Pick TWO variables from survey_clean.dta other than educ_raw and
* policy_support (for example: female and voted_last_election, or region
* and trust_science). For each of the two research questions below, decide
* whether ROW percent or COLUMN percent is the correct tool to answer it,
* and write your answer as a comment. Then run the actual `tabulate`
* command with the option you chose and confirm your answer against the
* output.
*
* Research question A: "Among [your row-variable category], what percentage
*   fall into [your column-variable category]?"
*   -> row percent, or column percent? (write your answer here)
*
* Research question B: "Among [your column-variable category], what
*   percentage fall into [your row-variable category]?"
*   -> row percent, or column percent? (write your answer here)
*
* tabulate ___ ___, row
* tabulate ___ ___, column
*
* Finally, write one sentence describing ONE specific cell using the
* percentage type you did NOT ask for above, to prove to yourself that it
* would have been the wrong denominator for that sentence.
