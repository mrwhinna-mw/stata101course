# Stata for Survey Researchers — A 14-Lesson Curriculum

A self-contained, hands-on Stata curriculum for people who analyze survey data
professionally (or academically) but have never used Stata before. If you are
comfortable with concepts like sampling weights, confidence intervals, and
regression coefficients — but have only ever touched them in SPSS, R, SAS,
Excel, or a GUI tool — this curriculum is built for you.

## Who this is for

- Survey researchers, policy analysts, and applied social scientists who need
  to learn Stata for a job, a project, or a course requirement.
- No prior Stata experience is assumed. Every command is introduced from
  scratch, including basics like what a do-file is.
- Basic statistics literacy IS assumed: you should already know, roughly,
  what a mean, a proportion, a confidence interval, a regression coefficient,
  and a p-value are. This curriculum teaches you how to produce and interpret
  those things correctly in Stata — including the survey-specific twists
  (weights, clustering, stratification) that general intro-stats courses
  often skip — not what they mean in the abstract.

## Prerequisites

- A licensed or trial copy of **Stata 18** (or later — the syntax used here
  is stable across recent versions). Stata is commercial software; see
  StataCorp, stata.com, for licensing and trial options. This curriculum
  does not require any particular Stata edition (SE/MP/BE) — everything
  here runs fine in the smallest supported edition.
- No prior Stata experience needed.
- Basic statistics literacy (see above).
- A handful of lessons (starting around Lesson 10-11) use free,
  community-contributed packages installed from within Stata itself — see
  "Community-contributed packages" below. No separate download or account is
  needed for these; they install directly from Stata with one command.

## How this repo is organized

```
data/
  build_synthetic_survey.do   # generates the synthetic raw data (instructors/curious learners only)
  survey_raw.csv              # messy raw survey data — the input to Lesson 01
  survey_clean.dta            # cleaned dataset — PRODUCED by Lesson 02, used by every lesson from 03 on
lessons/
  00_setup/
    00_setup.do
    00_setup_companion.docx
  01_import_and_inspect/
    01_import_and_inspect.do
    01_import_and_inspect_companion.docx
  ... one folder per lesson, numbered 00-13 ...
  13_capstone/
    13_capstone.do
    13_capstone_companion.docx
```

Each lesson folder contains exactly two files:

- **`NN_topic.do`** — a Stata do-file you open and run yourself in Stata's
  Do-file Editor. It contains the working commands for the lesson, heavily
  commented, plus a "YOUR TURN" exercise at the end for you to complete
  on your own.
- **`NN_topic_companion.docx`** — a companion document explaining the
  concepts in prose, meant to be read before you touch Stata for that
  lesson.

## The 14-lesson curriculum map

| # | Folder | Title | Est. time | What it covers |
|---|--------|-------|-----------|-----------------|
| 00 | `00_setup` | Setup & Orientation | 30 min | Stata interface tour, do-files vs. command line, comments, logs, working directories |
| 01 | `01_import_and_inspect` | Importing Data & First Look | 35 min | `import delimited`, `describe`/`codebook`, spotting messy data without fixing it yet |
| 02 | `02_cleaning_and_labels` | Data Cleaning & Labeling | 40 min | `destring`, recoding missing codes, deduplication, variable/value labels; **produces `survey_clean.dta`** |
| 03 | `03_help_and_navigation` | The Help System & Getting Unstuck | 30 min | `help`, `search`, `findit`, `ssc install`, reading error messages, community resources |
| 04 | `04_tabs_and_confidence_intervals` | Basic Tabulations & Confidence Intervals | 40 min | `tabulate`, `proportion`, `ci proportions`, interpreting survey CIs correctly |
| 05 | `05_weighting_basics` | Survey Weighting Basics | 45 min | pweight vs. fweight/iweight, `svyset`, `svy: tabulate`/`mean` vs. unweighted |
| 06 | `06_row_col_percentages` | Row vs. Column Percentages | 30 min | Reading two-way tables correctly — row/column/cell percentages |
| 07 | `07_crosstabs_and_tests` | Crosstabs with Statistical Tests | 35 min | chi2/exact tests, design-based `svy: tabulate`, effect size vs. significance |
| 08 | `08_intro_regression` | Introduction to Regression | 45 min | `regress` (OLS), `logit`/`logistic`, `margins`, interpreting coefficients/odds ratios |
| 09 | `09_regression_with_weights` | Regression with Survey Weights & Design | 40 min | `svy: regress`/`logit`, `subpop()` vs. `if`, design effects on standard errors |
| 10 | `10_categorical_outcomes` | Modeling Ordinal & Categorical Outcomes | 45 min | `ologit`, parallel-lines assumption, `mlogit`, predicted probabilities |
| 11 | `11_dominance_analysis` | Dominance Analysis for Ordinal Outcomes | 45 min | Relative importance analysis via `domin`/`domme`, Shapley-style decomposition |
| 12 | `12_latent_class_analysis` | Latent Class Analysis | 45 min | `gsem lclass`, choosing class count via BIC/AIC, posterior class assignment |
| 13 | `13_capstone` | Capstone Project | 45 min | Self-directed, end-to-end analysis exercising every prior lesson, with a grading rubric |

Total run time: roughly 9-10 hours across all 14 lessons.

## How to use each lesson

1. **Open the companion `.docx` first.** Read it before touching Stata —
   it explains the concepts and why they matter, without Stata syntax
   getting in the way.
2. **Open the `.do` file in Stata's Do-file Editor** (`Window > Do-file
   Editor`, or click the do-file editor icon in the Stata toolbar). Run it
   line-by-line or in small selected blocks rather than all at once the
   first time through, so you can watch each command's output as you go.
3. **Do the "YOUR TURN" exercise** at the end of the do-file before moving
   on to the next lesson. These exercises are where the actual learning
   happens — reading someone else's working code is not the same as
   writing your own.
4. Lessons are meant to be done **in order**. Later lessons assume you've
   completed earlier ones and frequently reference them directly (e.g.
   "see Lesson 05 for `svyset` syntax").

## A note on `data/survey_clean.dta`

`data/survey_clean.dta` is the canonical cleaned dataset used by every
lesson from Lesson 03 onward. **It does not exist in this repository until
you run Lesson 02** (`lessons/02_cleaning_and_labels/02_cleaning_and_labels.do`),
which builds it from the raw `data/survey_raw.csv` file and saves it out. If
you jump straight to a later lesson without having run Lesson 02 first (in
this Stata session or a previous one), `use "../../data/survey_clean.dta"`
will fail because the file genuinely isn't there yet — run Lesson 02 first.

## Community-contributed packages

Stata's built-in commands cover most of this curriculum, but a few advanced
methods starting around **Lesson 10-11** rely on free, community-contributed
packages distributed via the Boston College Statistical Software Components
(SSC) archive rather than shipping with Stata itself:

- `omodel` (Lesson 10) — tests the proportional-odds/parallel-lines
  assumption for ordinal models.
- `gologit2` (Lesson 10) — generalized ordered logit, referenced as the
  fallback if the parallel-lines assumption fails.
- `domin` / `domme` (Lesson 11) — dominance analysis / relative importance
  decomposition.

These are installed with a single line, e.g. `ssc install omodel`. Lesson 03
(The Help System & Getting Unstuck) covers `ssc install` in general, and each
of Lessons 10-11 also includes the specific install command inline right
before it's needed, so you don't need to remember to do anything ahead of
time.

## About the data

Every dataset in this curriculum is **fully synthetic**, generated
specifically for teaching purposes — it does not describe any real survey,
and no real respondents are represented in it. `data/build_synthetic_survey.do`
contains the exact, fully transparent generating process used to produce
`data/survey_raw.csv` (nothing about the data is a "black box"); you don't
need to run it as a learner, but it's there if you're curious how the
messiness in the raw file — miscoded missing values, inconsistent string
formatting, and so on — was constructed on purpose for Lessons 01-02 to clean
up.

## Where to go next

Once you've finished all 14 lessons, see the "Where to go next" section of
the Lesson 13 capstone companion document for pointers to StataCorp's full
documentation, UCLA IDRE's Stata pages, Statalist, and the Stata Journal —
resources for continuing to build Stata skills well beyond this curriculum.

## License / attribution

This curriculum's content (lessons, companion documents, and the synthetic
data-generating do-file) is provided as-is for educational use. You are free
to use, adapt, remix, and reuse it for your own teaching or learning,
including modifying it to fit your own courses or workshops. No warranty is
made about its fitness for any particular purpose — always double-check
generated Stata output against current StataCorp documentation, especially
for community-contributed packages, which are maintained independently and
can change over time.
