/*==============================================================================
LESSON 00 — SETUP & ORIENTATION
Lesson 0 of 14 — Stata Curriculum for Survey Researchers

PREREQUISITES:
    None. This is the first lesson in the curriculum.

LEARNING OBJECTIVES:
    - Understand what Stata is (and is not), and how licensing/versions work
    - Recognize the main windows in the Stata interface and what each is for
    - Understand the difference between typing commands directly vs. writing
      a do-file, and why real analytic work should always live in a do-file
    - Write and read Stata comments in all three supported styles
    - Set/check a working directory with `cd` and `pwd`
    - Start and stop a log file with `log using` / `log close`
    - Know the difference between running a do-file via the Editor's
      "Execute" button and running it from the Command window with `do`

ESTIMATED TIME: 30 minutes

NOTE: There is no dataset yet in this lesson. Every command below is either
      harmless housekeeping or a toy example. Lesson 01 is where we load
      real survey data.
==============================================================================*/


* --- 1. What is Stata? -----------------------------------------------------
* Stata is a combined statistics package + programming language sold by
* StataCorp. It is licensed per-seat/per-year (or perpetual, depending on the
* license type you or your institution purchased) and comes in a few flavors
* (Stata/BE, Stata/SE, Stata/MP) that mainly differ in how many variables/
* observations they can handle and how many processor cores they use. This
* curriculum was written and checked against Stata 18 syntax; nearly all of
* it will also run unmodified in Stata 15+.
*
* There is nothing to run in this section — it's just context. Read it, then
* move on to Section 2.


* --- 2. A tour of the interface (read this section; nothing to run) -------
* When you open Stata you will normally see several docked windows. You
* cannot see them from a do-file, so here is a plain-text tour:
*
*   Command window   - a single-line box at the bottom where you can type
*                       one command at a time and press Enter to run it.
*                       Good for quick, throwaway checks. Bad for anything
*                       you want to redo or hand to a colleague.
*   Results window    - the large central pane where output from every
*                       command you run (from the Command window OR a
*                       do-file) is printed, in order, like a transcript.
*   Review window     - a running history list of every command you've
*                       executed this session. Double-click an entry to
*                       re-run it, or right-click to copy it into a do-file.
*   Variables window  - lists every variable in the dataset currently in
*                       memory, along with its variable label. Empty until
*                       you load data (Lesson 01).
*   Properties window - shows metadata (name, label, type, format, value
*                       label) for whatever variable is currently selected
*                       in the Variables window.
*   Do-file Editor    - a separate text-editor window (opens with the
*                       "New Do-file Editor" toolbar button, or `doedit`)
*                       where you write and save .do files like this one.
*                       This is where essentially all of your real work
*                       should happen.


* --- 3. Command window vs. do-file: why do-files win -----------------------
* Typing directly into the Command window feels fast, but it leaves no
* record: if you close Stata, that history is much harder to recover and
* impossible to hand to someone else as a script. A do-file is a plain-text
* file of Stata commands, run top to bottom, that:
*   - can be re-run identically at any time (reproducibility)
*   - can be version-controlled, emailed, reviewed, or published alongside
*     a paper or report
*   - documents your own reasoning to your future self via comments
* Professional convention (and this curriculum's convention) is: prototype a
* single command in the Command window if you like, but the moment it works,
* move it into a do-file. Nothing you need to keep should live only in your
* command history.


* --- 4. Comment syntax ------------------------------------------------------
* Stata supports three comment styles, all used in this curriculum:

* A whole line starting with an asterisk is a comment (this line, e.g.)

di "hello"   // a double-slash comment runs to the end of the line

/* a slash-star comment can
   span multiple lines, which is handy for
   the header blocks at the top of every lesson do-file */

display "Comments never execute — Stata just skips over them."   // confirms the point above


* --- 5. Working directories: cd and pwd -------------------------------------
pwd   // "print working directory" - shows Stata's current folder; run this first whenever you're unsure where you are

* `cd` changes Stata's working directory, the same way `cd` works in a
* terminal. Once you `cd` somewhere, you can refer to files in that folder
* by their filename alone instead of typing a full path every time.
* Uncomment and edit the line below to point at wherever you keep this
* curriculum on your own machine, then re-run this do-file:

* cd "/path/to/stata-survey-curriculum/lessons/00_setup"

di as text "If the cd line above is commented out, Stata is just using" ///
    " whatever folder it already started in."


* --- 6. which: checking what Stata thinks a command is ----------------------
which display   // "which" reports whether a name is a built-in command, an ado-file, and where that ado-file lives on disk; useful for troubleshooting later when you install community-contributed commands


* --- 7. Logs: log using ... / log close -------------------------------------
* A log is a saved transcript of everything printed to the Results window.
* Keeping a log for every real analysis session is good practice: if a
* number in a report is ever questioned, you can point to the exact log
* that produced it.

capture log close   // "capture" swallows the error if no log is currently open, so this line is always safe to run
log using "00_setup_demo_log.log", replace text   // opens (or overwrites, via `replace`) a plain-text log file in the current working directory

display "This line, and everything above/below it, is being recorded to the log."

log close   // always close a log when you're done, or the file may not be flushed/finished properly


* --- 8. Basic housekeeping: clear ---------------------------------------------
clear   // wipes any dataset currently in memory; good habit at the top of a do-file so you never accidentally analyze leftover data from a previous run
di as result "Memory cleared. Nothing is loaded — that's expected, we have no data yet in Lesson 00."


* --- 9. Running a do-file -----------------------------------------------------
* You have two equivalent ways to run this file:
*   (a) With this file open in the Do-file Editor, click the "Execute
*       (do)" button (the running-person icon), or press the keyboard
*       shortcut shown in the Editor's toolbar.
*   (b) From the Command window (or another do-file), type:
*         do "00_setup.do"
*       using either a full path or a relative path from the current
*       working directory.
* Both methods run every line top to bottom and print all output to the
* Results window / active log exactly the same way.


* ============ YOUR TURN ============
* Write a NEW, separate 5-line do-file (not this one) that does the
* following, in order:
*   1. Sets the working directory to this lesson's folder (00_setup)
*   2. Opens a log file called "your_turn_log.log", using `replace`
*   3. Displays a short message of your choosing with `display`
*   4. Closes the log with `log close`
*   5. Clears memory with `clear`
* Save it as "00_setup_your_turn.do" in this same folder, then run it
* using the Do-file Editor's Execute button. Open the resulting .log file
* in a plain-text editor afterward to confirm it captured your message.
*
* cd ...
*
* log using ...
*
* display ...
*
* log close
*
* clear
