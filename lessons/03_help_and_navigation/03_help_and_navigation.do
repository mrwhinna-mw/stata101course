/*==============================================================================
    LESSON 03 — THE HELP SYSTEM & GETTING UNSTUCK
    Lesson 03 of 14 — Stata Curriculum for Survey Researchers

    PREREQUISITES
      - Lesson 00 (setup), Lesson 01 (import & inspect), Lesson 02 (cleaning
        & labels) completed.
      - data/survey_clean.dta exists (produced by Lesson 02).

    LEARNING OBJECTIVES
      By the end of this lesson you will be able to:
      - Open and read a Stata help file, including its syntax diagram
        (square brackets, underlining, [if]/[in]/[weight] qualifiers).
      - Use `help contents` and the Viewer's search box to browse topics.
      - Choose between `search` and `findit` depending on whether you want
        official/FAQ material or also user-written community packages.
      - Use `which` to tell a built-in command apart from an installed
        ado-file, and know where that ado-file lives on disk.
      - Install a community-contributed package with `ssc install` or
        `net install`.
      - Read a Stata error message and its associated return code, r(###),
        and look up what that code means.
      - Locate the official PDF manuals and know where to go for community
        help (Statalist, UCLA IDRE).

    ESTIMATED TIME: ~30 minutes

    A NOTE ON FILE PATHS
      This do-file lives in lessons/03_help_and_navigation/. The data lives
      in data/, two levels up from this folder. That is why every `use`
      statement in this curriculum begins with "../../data/".
==============================================================================*/

version 18
clear all
set more off

* -----------------------------------------------------------------------
* 1. OPEN THE DATA FOR A FEW LIVE EXAMPLES
*    (Today's focus is meta-skills, not the data itself, but it helps to
*    have real variables on hand to demonstrate help/search/which against.)
* -----------------------------------------------------------------------
use "../../data/survey_clean.dta", clear   // canonical cleaned dataset from Lesson 02
describe                                    // quick refresher on what variables exist


* -----------------------------------------------------------------------
* 2. READING A HELP FILE
*    `help <command>` opens the Viewer to that command's help file. Every
*    Stata help file starts with a SYNTAX DIAGRAM. Learn to read it once
*    and you can read every command's help file for the rest of your career.
*
*    Syntax diagram conventions:
*      - Square brackets [ ] mean the piece inside is OPTIONAL.
*      - An underlined portion of a word is the MINIMUM ABBREVIATION you
*        are allowed to type (e.g., `tabulate` can be abbreviated `tab`,
*        `summarize` can be abbreviated `su`).
*      - [if] and [in] are qualifiers that restrict which observations a
*        command uses (an if-condition, or an observation range).
*      - [weight] shown in a syntax diagram means the command accepts at
*        least one type of Stata weight (pweight, fweight, iweight,
*        aweight) — which types are allowed are listed further down the
*        help file under "Weights".
* -----------------------------------------------------------------------
help tabulate     // open the help file for tabulate; look at the syntax diagram at the top
help summarize    // compare: note the [if] [in] [weight] qualifiers here too
help regress      // a more complex example, useful preview of Lesson 08


* -----------------------------------------------------------------------
* 3. BROWSING WHEN YOU DON'T KNOW THE COMMAND NAME
*    `help contents` opens Stata's full table of contents, organized by
*    manual (e.g., [R] Base Reference, [D] Data Management, [SVY] Survey
*    Data). The Viewer also has a search box in its toolbar — typing a
*    keyword there searches installed help files, similar to `search`.
* -----------------------------------------------------------------------
help contents     // browse the full set of manuals and topics


* -----------------------------------------------------------------------
* 4. search VS. findit
*    - `search <keyword>` looks through Stata's official documentation,
*      FAQs, and the Stata Journal for your keyword. It does NOT search
*      the internet.
*    - `findit <keyword>` runs `search` AND ALSO searches user-written
*      packages hosted online (SSC, personal websites, etc.). Use `findit`
*      when you suspect "someone must have written a command for this"
*      (e.g., a specialized survey diagnostic or a plotting style).
* -----------------------------------------------------------------------
search survey weights          // official docs/FAQs about survey weighting
* findit dominance analysis    // (commented out: requires internet access)
                                 // uncomment to see user-written packages
                                 // related to a keyword, e.g. before Lesson 11


* -----------------------------------------------------------------------
* 5. IS THIS A BUILT-IN COMMAND OR SOMETHING SOMEONE INSTALLED?
*    `which <command>` tells you where a command's underlying .ado file
*    lives. Built-in commands report they are "built-in command"; a
*    community-contributed command reports a file path (e.g., in your
*    PERSONAL or PLUS ado-path), which tells you it was installed, not
*    part of official Stata.
* -----------------------------------------------------------------------
which summarize    // built-in: reports "built-in command: summarize"
which regress      // also built-in
* which estout      // (commented out: only works if estout has been installed)
                     // if installed, reports a file path like
                     // c:\ado\plus\e\estout.ado


* -----------------------------------------------------------------------
* 6. INSTALLING COMMUNITY-CONTRIBUTED PACKAGES
*    Most user-written commands are distributed via SSC (Statistical
*    Software Components) or as personal "net" packages.
*      ssc install <pkgname>     // easiest route for anything on SSC
*      ssc describe <pkgname>    // preview what a package does before installing
*      net install <pkgname>, from(<url>)   // for packages not on SSC
*    Example (do not run without internet access / instructor permission):
* -----------------------------------------------------------------------
* ssc install estout, replace     // installs a popular table-formatting package
* ssc describe outreg2            // preview a package's help file before installing


* -----------------------------------------------------------------------
* 7. READING ERROR MESSAGES AND RETURN CODES
*    When a command fails, Stata prints a short message and, on the
*    far right, a return code in parentheses like r(198). That number is
*    searchable: `search rc <number>` (or `search r(198)`, both work)
*    pulls up the official explanation of exactly what went wrong.
*
*    Two error messages you will see constantly as a beginner:
*      - "variable not found"      -> r(111): you mistyped a variable name,
*                                     or that variable does not exist in
*                                     the dataset currently in memory.
*      - "type mismatch"            -> r(109): you tried to do something
*                                     numeric to a string variable (or
*                                     vice versa) — e.g. `summarize region_str`
*                                     when region_str is a string.
* -----------------------------------------------------------------------
* The next line is deliberately WRONG on purpose, to show a real error:
capture noisily summarize satisfction   // (typo: "satisfction") -> r(111) variable not found
di as txt "See how Stata reported r(111) above? Try: search rc 111"
* search rc 111                          // uncomment to look up what r(111) means


* -----------------------------------------------------------------------
* 8. WHERE THE OFFICIAL MANUALS LIVE, AND WHERE THE COMMUNITY IS
*    - Full PDF manuals: Stata menu bar -> Help -> PDF Documentation.
*      These are the same manuals referenced in help files (e.g. [SVY],
*      [R], [D]) but with much longer worked examples.
*    - Statalist (https://www.statalist.org): the main community forum,
*      monitored by StataCorp staff and expert users. Search before posting.
*    - UCLA IDRE Statistical Consulting (https://stats.oarc.ucla.edu/stata/):
*      excellent free tutorials and worked examples, especially for
*      regression and survey-related topics used later in this course.
* -----------------------------------------------------------------------
di as txt "Help menu > PDF Documentation for the official manuals."
di as txt "Community help: statalist.org and stats.oarc.ucla.edu/stata/"


* ============ YOUR TURN ============
* Open the help file for `tabulate` (you already did this in Section 2,
* but look more closely this time).
*
*   1. Run: help tabulate
*   2. Scroll to the "options" section of the one-way tabulate syntax.
*   3. Find the option that would give you ROW PERCENTAGES in a two-way
*      tabulation. Write its name in a comment below.
*   4. Do NOT run it yet — we will use it properly in Lesson 06
*      (Row/Column Percentages). Just identify it for now.
*
* help tabulate

* Your answer (as a comment):
* The option is: __________
