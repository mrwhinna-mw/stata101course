/*==============================================================================
LESSON 01 — IMPORTING DATA & FIRST LOOK
Lesson 1 of 14 — Stata Curriculum for Survey Researchers

PREREQUISITES:
    Lesson 00 (Setup & Orientation) — comment syntax, cd, log, clear

LEARNING OBJECTIVES:
    - Import a raw .csv file with `import delimited` and know which options
      matter (`varnames`, `clear`, `case`, `encoding`)
    - Recognize common import pitfalls: wrong delimiter, wrong header row,
      character encoding issues, and numeric-looking columns imported as
      string
    - Use `describe` and `codebook` (including `codebook, compact`) to get
      an inventory of a new dataset
    - Understand why `browse`/`edit` are risky tools for real inspection
    - Use `count`, `summarize`, `summarize, detail`, and `list` to spot-check
      the data
    - Identify (but NOT yet fix) messy fields: string `age`/`income_k`,
      -99 "don't know" codes, and inconsistent `region_str` values

ESTIMATED TIME: 35 minutes

NOTE: This do-file assumes Stata is run from this lesson's folder
      (lessons/01_import_and_inspect/); adjust the `cd` line below if your
      own folder layout differs. The data file is one level up in
      ../../data/ relative to this lesson's folder.

IMPORTANT: We only LOOK at the data in this lesson. We do not clean or
    fix anything here — every issue we notice below gets fixed in Lesson 02.
    We do not save any modified copy of the data at the end of this file;
    Lesson 02 starts fresh from data/survey_raw.csv, exactly as this lesson
    does.
==============================================================================*/

capture log close
clear   // start from a clean slate — good habit at the top of any do-file

* cd "lessons/01_import_and_inspect"   // uncomment/edit if Stata did not already start here


* --- 1. Importing the raw CSV -----------------------------------------------
* `import delimited` reads plain-text delimited files (csv, tab, etc.).
* Key options used here:
*   varnames(1)  - tells Stata that ROW 1 of the file holds variable names,
*                  not data. Forgetting this is one of the most common
*                  import mistakes: Stata will otherwise name your columns
*                  v1, v2, v3... and treat your real header row as if it
*                  were the first observation.
*   case(preserve) - keeps variable names exactly as they appear in the
*                  file instead of Stata's default of lower-casing them;
*                  harmless here since our headers are already lowercase,
*                  but worth knowing about for files with mixed-case headers.
*   clear        - allows Stata to discard whatever is currently in memory
*                  (nothing, here, since we just ran `clear` above) to make
*                  room for the incoming import.
import delimited "../../data/survey_raw.csv", varnames(1) case(preserve) clear

* A note on pitfalls we are NOT hitting here, but that are common in the
* wild:
*   - Wrong delimiter: a file that is actually tab- or semicolon-delimited
*     but is imported with the default comma delimiter will produce one
*     giant garbled string variable. If that happens, re-import with the
*     `delimiter(...)` option or use `import delimited` with no options
*     first and inspect before deciding.
*   - Encoding problems: files exported from some survey platforms are
*     saved in an encoding other than UTF-8 (e.g. Windows-1252), which can
*     turn accented characters or curly quotes into garbage symbols. The
*     `encoding()` option on `import delimited` lets you specify the source
*     encoding when the default guess is wrong.
*   - Numeric-looking columns imported as string: if even ONE cell in a
*     column that looks numeric contains text (like "REFUSED" or "N/A"),
*     Stata imports the ENTIRE column as a string variable rather than a
*     number. We will see this happen below with `age` and `income_k`.


* --- 2. First inventory: describe -------------------------------------------
describe   // one line per variable: name, storage type, display format, and variable label — your fastest way to see the whole dataset's shape at a glance

* Look closely at the "storage type" column for `age` and `income_k`.
* Both should show up as `str*` (string) rather than a numeric type like
* `int`, `long`, `float`, or `double` — exactly the "numeric column
* imported as string" pitfall described above, caused by REFUSED/N/A/blank
* entries mixed in with numbers.


* --- 3. A fuller inventory: codebook -----------------------------------------
* `codebook` is more detailed than `describe`: for each variable it shows
* the number of missing/unique values, the range or list of distinct
* values, and (for labeled variables) how the labels map to codes.
codebook age income_k   // focus first on exactly the two variables we suspect are messy

* `codebook, compact` gives one summary line per variable for every
* variable in the dataset at once — useful as a first-pass scan before
* drilling into individual variables with plain `codebook varname`.
codebook, compact


* --- 4. Why not just browse/edit the data? -----------------------------------
* Stata's spreadsheet-style viewers exist:
*   browse   // opens a READ-ONLY spreadsheet view of the data in memory
*   edit     // opens the SAME spreadsheet view, but editable
* Both are useful for a quick eyeball scan of a handful of rows, but they
* are a poor substitute for real inspection on anything but a tiny dataset:
* you cannot easily spot a systematic problem (like 4% of a column being
* miscoded -99) by scrolling through 1,204 rows by eye. Worse, `edit` lets
* you accidentally type over a cell with no undo history tied to a
* do-file, silently breaking reproducibility. This curriculum never uses
* `edit` on real analysis data. `browse` is safe to open at the console
* for a casual look, but it is intentionally not used as a command in this
* do-file — everything we need to know we get from commands below that
* leave a record in the log.


* --- 5. Basic counts and summaries -------------------------------------------
count   // total number of observations currently in memory
di as result "Raw row count above should read 1,204: 1,200 base respondents plus 4 intentional duplicate rows we will find in Lesson 02."

summarize   // quick numeric summary (mean, sd, min, max) for every numeric variable; note age and income_k are ABSENT from this list because they are still stored as strings

summarize weight psu female educ_raw trust_gov trust_media trust_science trust_local policy_support voted_last_election satisfaction

summarize satisfaction, detail   // the `detail` option adds percentiles, skewness, and kurtosis — useful for a continuous outcome like life satisfaction

list respondent_id region_str age income_k trust_gov in 1/10   // eyeball the first 10 rows of exactly the columns we're worried about


* --- 6. Spotting the messy fields (looking only — no fixes yet) --------------
* (a) age and income_k as strings
* We already saw both listed as str* types in `describe`. Let's confirm
* the specific non-numeric values responsible, without changing anything.
tab age if !inrange(real(age), 0, 120)   // real() tries to convert the string to a number and returns missing (.) for anything that fails; this shows us the actual text values (e.g. "REFUSED") jamming up the age column

tab income_k if income_k == "" | income_k == "N/A"   // shows how the blank/"N/A" entries in income_k are distributed - just a look, not a fix

* (b) The -99 "don't know" code on the trust items
* -99 is a classic legacy survey missing-data code: a number that is
* clearly not a real Likert response (which only runs 1-5) but that
* Stata, having imported the column as ordinary numeric data, currently
* treats as a valid, very-low value. This will bias any mean/summary
* computed on trust_gov et al. until we recode it in Lesson 02.
tab trust_gov, missing   // "missing" option shows a row for true Stata-missing (.) values too, though here -99 is just an ordinary (wrong) numeric code, not a true missing value yet
tab trust_media
tab trust_science
tab trust_local

* (c) Messy region_str strings
* Notice the inconsistent capitalization and stray leading/trailing
* spaces below — the same four regions written four different ways.
tab region_str   // by default `tab` does NOT trim whitespace or fold case, so " northeast", "SOUTH", "Midwest ", and "west" each appear as their own separate category here


* --- 7. Wrapping up this lesson ----------------------------------------------
* We are deliberately NOT saving anything at the end of this do-file. The
* dataset currently in memory has NOT been cleaned — it is exactly what
* `import delimited` produced from survey_raw.csv, nothing more. Lesson 02
* starts over from data/survey_raw.csv (via a fresh `import delimited`) and
* performs every fix identified above, ending with a saved
* data/survey_clean.dta that every later lesson in this curriculum will
* `use`.

di as result "End of Lesson 01. Nothing was saved on purpose — see the note above."


* ============ YOUR TURN ============
* Using only commands introduced in this lesson (no fixes yet!):
*   1. Run `codebook policy_support` and, in a comment below, write one
*      sentence describing what you see (min/max, any unexpected values).
*   2. Run `summarize weight, detail` and, in a comment, note the min and
*      max weight you observe. Why do you think survey weights are
*      sometimes far from 1.0? (You don't need to know the exact answer
*      yet — just write your best guess.)
*   3. Use `list` to print respondent_id and region_str for observations
*      15 and 16 only (hint: `in 15/16`). What do you notice, and which
*      later lesson do you think will need to deal with it?
*
* codebook policy_support
*
* summarize weight, detail
*
* list respondent_id region_str in 15/16
