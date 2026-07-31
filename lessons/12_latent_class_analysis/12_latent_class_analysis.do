/*==============================================================================
LESSON 12 — LATENT CLASS ANALYSIS (LCA) WITH gsem
Lesson 12 of 14 — Stata Curriculum for Survey Researchers

PREREQUISITES:
    - Lessons 08-10 (regression, weighted regression, categorical outcomes —
      ologit/mlogit). This lesson assumes you are comfortable reading a
      coefficient table and interpreting an ordinal/categorical model, but
      it assumes ZERO prior exposure to mixture models or latent-variable
      models of any kind. We build the intuition from scratch.

LEARNING OBJECTIVES:
    - Explain, in plain language, what a latent class model is trying to
      recover and why "local independence" is the key assumption that makes
      the whole idea work
    - Explain how LCA (categorical latent variable) differs from factor
      analysis (continuous latent variable)
    - Fit a latent class model in Stata using `gsem ... , lclass(C #)`
      and read the `<-` syntax correctly
    - Fit a SEQUENCE of models with different numbers of classes and choose
      among them using `estat ic` (AIC/BIC), not fit statistics alone
    - Understand why multiple random starting values matter for these
      models (local maxima / convergence risk) and how `startvalues()`
      is used to address it
    - Extract posterior class-membership probabilities with `predict ...,
      classposteriorpr` and assign each respondent to a most-likely class
    - Understand that class LABELS ("high trust," "low trust," etc.) are
      an interpretive step performed by the analyst after inspecting
      class-specific response probabilities — Stata does not supply labels
    - Approach LCA output with appropriate humility about convergence and
      local maxima

ESTIMATED TIME: 45 minutes

IMPORTANT NOTE — NO LIVE STATA IN THIS ENVIRONMENT:
    This lesson was written without access to a running Stata session, so
    no output below is from an actual run. Every command has been hand-
    checked against Stata 18 `gsem`/`lclass` syntax as documented in the
    [SEM] Structural Equation Modeling Reference Manual, but you should
    still run `help gsem` and `help lclass` yourself before relying on any
    option name here, especially the exact `startvalues()` suboptions
    flagged below — those are the syntax detail we are least certain about
    at time of writing.
==============================================================================*/


* --- 0. Setup ---------------------------------------------------------------
clear all                                    // start with a clean slate
set more off                                 // don't pause output a screen at a time

use "../../data/survey_clean.dta", clear     // load the Lesson 02 cleaned dataset

describe trust_gov trust_media trust_science trust_local   // remind ourselves these are the four 1-5 Likert indicators we'll model


* --- 1. The core idea of latent class analysis (plain language) -------------

* You did NOT ask respondents "what type of trust-truster are you?" You asked
* four separate questions (trust_gov, trust_media, trust_science, trust_local).
* Those four answers are correlated with each other in the raw data — someone
* who trusts government a lot also tends to trust science and media more than
* average. Latent class analysis (LCA) proposes an explanation for WHY: there
* is a small number of unobserved ("latent") subgroups of respondents — call
* them "classes" — and within each class, the four indicators are (close to)
* STATISTICALLY INDEPENDENT of each other. All of the correlation you see in
* the pooled sample is explained by the fact that the sample is a mixture of
* these classes, each with a different typical response pattern. This
* assumption — indicators are independent of each other ONCE YOU CONDITION ON
* CLASS MEMBERSHIP — is called "local independence," and it's the assumption
* that makes LCA identifiable and interpretable. See Collins & Lanza (2010),
* chapter 1-2, for the canonical textbook treatment of this idea.


* --- 2. How this differs from factor analysis --------------------------------

* Factor analysis also posits a latent (unobserved) variable behind a set of
* observed indicators, but the latent variable there is CONTINUOUS (a "trust
* factor" score that could be -2.3 or +0.8 for any given person), and the
* model estimates continuous FACTOR LOADINGS describing how strongly each
* indicator relates to that continuous trait. LCA instead posits a
* CATEGORICAL latent variable (a small, fixed number of discrete classes,
* not a continuum), and instead of loadings it estimates CLASS-SPECIFIC
* response probabilities — e.g., "in Class 1, the probability of answering
* '5 - Strongly agree' to trust_gov is 0.62; in Class 2 it's 0.04." Same
* general family of "latent variable" models, different kind of latent
* variable, different kind of output to interpret.


* --- 3. Fitting a 2-class model with gsem -------------------------------------

* `gsem` (generalized structural equation modeling) is Stata's modern engine
* for latent class analysis. The basic syntax for LCA is:
*
*     gsem (trust_gov trust_media trust_science trust_local <-), ///
*         logit lclass(C 2)
*
* Reading this:
*   - the four trust_* variables in parentheses are the "measurement" part
*     of the model: the indicators
*   - `<-` followed by NOTHING means "regress each of these indicators on
*     the latent class variable ONLY" — there are no other observed
*     covariates predicting the indicators in this basic specification
*   - `logit` sets the measurement-model link/family gsem uses for these
*     indicators. Be precise about what this actually does: our trust_*
*     items are 5-category ordinal Likert items, and `logit` in this context
*     tells gsem to model each indicator as a set of binary logits across its
*     categories (Stata's standard multinomial-style handling of a
*     multi-category outcome under `lclass`), NOT a model that specially
*     exploits the ORDERING of "strongly disagree < ... < strongly agree."
*     Stata's gsem family/link options also include `oprobit`/`ologit`-style
*     ordinal links, which WOULD respect the 1-5 ordering explicitly and may
*     be more appropriate for genuinely ordinal indicators like these. We use
*     the categorical `logit` link for this worked example because it is the
*     more commonly demonstrated default in introductory LCA treatments and
*     keeps the class-specific output (a probability per category) easy to
*     read, but we are flagging honestly that an ordinal link is a legitimate
*     — arguably more appropriate — alternative worth trying yourself with
*     `help gsem` once you've worked through this lesson.
*   - `lclass(C 2)` tells gsem the latent class variable is named C and has
*     2 categories (2 classes) for this run

gsem (trust_gov trust_media trust_science trust_local <-), logit lclass(C 2)   // fit the 2-class LCA measurement model
estat ic                                     // AIC/BIC for the 2-class model, saved for later comparison


* --- 4. Fitting a SEQUENCE of models and comparing class counts --------------

* A latent class model with MORE classes can always fit the observed data at
* least as well as one with fewer classes (it's a more flexible model), so
* in-sample fit alone will never tell you to stop adding classes. Instead we
* use a penalized fit statistic — BIC (Bayesian Information Criterion) is
* generally preferred over AIC for choosing the number of classes in LCA,
* because BIC penalizes additional parameters more heavily and tends to
* recover the true/parsimonious number of classes more reliably in
* simulation studies (see Collins & Lanza 2010; Nylund, Asparouhov &
* Muthen-style simulation literature more broadly). Lower BIC (and AIC) is
* better. We also never choose class count on fit statistics ALONE — a
* solution should also be substantively interpretable (Section 6 below).

* IMPORTANT CONVERGENCE CAVEAT BEFORE YOU RUN ANY OF THIS:
* LCA models fit by maximum likelihood can converge to a LOCAL maximum
* instead of the true best-fitting (global) solution, and where you end up
* can depend on the starting values the optimizer uses. It is standard
* practice to re-fit each class-count model from several different random
* starting points and confirm the best log-likelihood is reached more than
* once (a sign you've likely found the global maximum rather than an
* unstable local one). Stata's `lclass` supports a `startvalues()` option
* for this, including a random-draws mode — the general form is something
* like:
*
*     gsem (...), logit lclass(C 2) startvalues(randomid, draws(20))
*
* FLAG — NOT 100% CERTAIN: we are confident `startvalues()` exists and that
* a random/multiple-draws mode is part of it, but we are NOT fully certain
* of the exact suboption spelling/defaults (e.g. whether it's `randomid`,
* how `draws()` is specified, or what Stata's default number of draws is)
* as of Stata 18. CONFIRM the exact syntax with `help gsem` and `help
* lclass` before you run this for real — do not copy the line above blindly.

* 2-class model (already fit above; re-shown here for a clean side-by-side sequence)
gsem (trust_gov trust_media trust_science trust_local <-), logit lclass(C 2)   // 2-class solution
estat ic                                     // record AIC/BIC for C=2

* 3-class model
gsem (trust_gov trust_media trust_science trust_local <-), logit lclass(C 3)   // 3-class solution — e.g. could recover a "mixed/institution-selective" middle group
estat ic                                     // record AIC/BIC for C=3

* 4-class model
gsem (trust_gov trust_media trust_science trust_local <-), logit lclass(C 4)   // 4-class solution — one more class than we substantively expect, fit for comparison
estat ic                                     // record AIC/BIC for C=4

* Compare the three `estat ic` outputs by eye (or copy the BIC column into a
* table). Given how these four indicators were generated from a single
* shared underlying trust factor plus noise, a 2-3 class solution is the
* realistic, recoverable structure here (e.g. "generally high trust,"
* "generally low trust," and possibly a mixed/institution-selective middle
* group) — but confirm that expectation against your OWN BIC numbers and
* substantive read of the class-specific probabilities, not against this
* comment.


* --- 5. After choosing a class count: class probabilities and assignment ----

* Suppose the 3-class model is your chosen solution based on BIC plus
* interpretability (re-fit it here so the rest of this section refers to it):
gsem (trust_gov trust_media trust_science trust_local <-), logit lclass(C 3)   // re-fit the chosen 3-class model so the commands below act on it

estat lcprob                                 // average (marginal) class-membership probabilities across the whole sample — "what share of respondents are in each class, on average"

estat lcmean                                 // class-specific means/response probabilities for each indicator — THIS is what you read to decide what each class "means" substantively

* `predict` with `classposteriorpr` computes, for EACH RESPONDENT, their
* estimated POSTERIOR probability of belonging to each class given their
* own observed answers to the four trust_* items (Bayes' rule applied to
* the fitted model) — these are per-respondent probabilities, not the
* sample-average ones from `estat lcprob` above.
predict classpost*, classposteriorpr         // creates one variable per class: classpost1, classpost2, classpost3 = P(class k | this respondent's answers)

* For downstream description (tables, cross-tabs, simple profiling — NOT a
* formal part of the mixture model itself), it's common to assign each
* respondent to their single most likely ("modal") class:
egen modal_class = rowmax(classpost1 classpost2 classpost3)   // largest posterior probability across the three class variables
gen assigned_class = .                        // placeholder for the assigned class number
replace assigned_class = 1 if classpost1 == modal_class       // assign to class 1 if it has the highest posterior probability
replace assigned_class = 2 if classpost2 == modal_class       // assign to class 2 if it has the highest posterior probability
replace assigned_class = 3 if classpost3 == modal_class       // assign to class 3 if it has the highest posterior probability

* A simple, informal validation step (NOT part of the mixture model itself):
* cross-tabbing the assigned class against variables the model never saw,
* to see whether the classes "make sense" against outside information.
tab assigned_class educ_raw, col               // does class membership relate sensibly to education?
tab assigned_class female, col                  // ...or to gender?
summarize age, detail                           // (you could also `bysort assigned_class: summarize age` to compare age across classes)
bysort assigned_class: summarize age            // mean/SD of age within each assigned class, as an informal validity check


* --- 6. Labeling classes is YOUR job, not Stata's ----------------------------

* Stata will never hand you a variable that says "high trust" or "low
* trust" — it only gives you numbered classes (1, 2, 3, ...) and, via
* `estat lcmean`, the class-specific response probabilities for each
* indicator. YOU inspect those probabilities and decide what story each
* class tells. For example, if `estat lcmean` shows Class 1 has a high
* estimated probability of "Agree"/"Strongly agree" responses across all
* four trust_* items, and Class 2 shows the opposite pattern, you might
* label them (in your write-up, not in Stata) "Class 1: broadly high
* trust" and "Class 2: broadly low trust." If a third class shows high
* trust in science/local but low trust in government/media, you might call
* it something like "institution-selective trust." These labels are
* interpretive summaries you are proposing to your reader, not objective
* facts the model discovered — a different analyst looking at the same
* `estat lcmean` table could reasonably propose different labels, and you
* should present the underlying probability table alongside your labels so
* readers can judge for themselves.


* --- 7. A closing caution on convergence and computational cost -------------

* LCA models fit via `gsem ... lclass()` are more computationally demanding
* and more convergence-sensitive than the regression models from Lessons
* 08-10. Do not treat a single run's output as ground truth: watch for
* convergence warnings/non-concave messages in the output, refit with
* different starting values (Section 4) and confirm you get the same
* maximized log-likelihood more than once, and be skeptical of a solution
* that only appears from one particular starting point. Larger indicator
* sets and higher class counts make this worse, not better. This
* sensitivity is a well-documented feature of finite mixture models
* generally (Collins & Lanza 2010), not a sign you are doing something
* wrong.

* For context: dedicated latent class software exists outside Stata too —
* Vermunt & Magidson's Latent GOLD is the best-known standalone LCA/LTA
* package and predates gsem's LCA capability by many years — but `gsem` in
* Stata 18 covers the core LCA use case shown in this lesson without
* needing a separate program.


* --- Sources referenced in this lesson ---------------------------------------
* Collins, L. M., & Lanza, S. T. (2010). Latent Class and Latent Transition
*   Analysis: With Applications in the Social, Behavioral, and Health
*   Sciences. Wiley.
* StataCorp. Stata 18 Structural Equation Modeling Reference Manual [SEM]:
*   see the `gsem` entry and the "Latent class analysis" section /
*   `lclass()` option documentation.


* ============ YOUR TURN ============
* 1. Fit your OWN 3-class model exactly as in Section 4 (or re-use the one
*    you already ran) and write down its BIC from `estat ic`.
* 2. Fit a 2-class model and write down ITS BIC.
* 3. In a comment below, state which of the two has the LOWER (better) BIC,
*    and whether that matches the "2-3 classes" expectation described in
*    Section 4.
* 4. Run `estat lcmean` for whichever of the two models you prefer and, in
*    a comment, propose a short substantive label for each class based on
*    the response probabilities you see (remember: labels are your
*    interpretive judgment, not something Stata outputs for you).
*
* gsem (trust_gov trust_media trust_science trust_local <-), logit lclass(C 2)
* estat ic
* // BIC for 2-class model: ...
*
* gsem (trust_gov trust_media trust_science trust_local <-), logit lclass(C 3)
* estat ic
* // BIC for 3-class model: ...
* // Which model wins on BIC, and does that match Section 4's expectation? ...
*
* estat lcmean
* // Class 1 label + reasoning: ...
* // Class 2 label + reasoning: ...
* // Class 3 label + reasoning (if applicable): ...
