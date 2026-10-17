# Sudoku: Game Design Document

Owner: lead-game-designer. Approved by Bart at Hard Stop 1, 2026-10-11. Where this document disagrees with docs/BRIEF.md, the brief wins, unless Bart decided otherwise (CLAUDE.md, "Decisions from Bart after the brief").

Change log: 2026-10-11, Phase 2: updated for Bart's Hard Stop 1 decisions (his answers to the three questions, the New best rule in 12.1 with AT-67, a hand-crossed digit drawn on top of its X, ring layout A, the Pop light and Pop dark skins, the screen sizes in AT-66), and corrected the example scores in section 13 and AT-53 to match the score formula. Later in Phase 2: added the Settings line for Auto Cross (5.2), and the rule that taps after a lesson step's answer are ignored until Next (15.4, AT-63). 2026-10-12, Phase 3: updated for Bart's Hard Stop 2 decisions: a givens floor for Beginner and Easy (11.4, AT-68) and the hint highlight of candidates to cross (2.3, 10.2, AT-69). 2026-10-12, Phase 6: window shapes for foldables and split screen, with Hint at the far end in side by side (2.4), the too small message and what it does to the puzzle (8, 8.1, 14), and AT-70 and AT-71. 2026-10-14: Bart's title screen. Every app start opens it, with PLAY, INFO and ABOUT (15.0); the lesson 1 offer moved from app start to the first PLAY (15.3); the main menu (15.1); the last level started is saved (14, 15.2); the exact Info screen text (15.5) and About screen text (15.6); Continue became PLAY in 7.3 and in the restart tests; AT-72 to AT-78. 2026-10-14, later: Bart's Show candidates switch (4.5), with the matching lines in 1, 2.1, 3.1, 4.2, 5.1, 7.1, 10.2, 14, 15.4, 15.5 and 16, and AT-79 to AT-85. Bart's MENU button on the title screen (1, 15.0, 15.1, 15.5 Getting around, AT-72, AT-76). 2026-10-17: Bart's Buy me a coffee button on the title screen and the About screen, and the new About card: credit, Play, Inc. copyright, contact and privacy lines; the rule against "github" retired (1, 15.0, 15.5 Getting around, 15.6, AT-72, AT-78, AT-86).

## 1. Summary for Bart

Each line is one decision. The number in brackets is the section with the reason and worked examples.

### Three recommendations, decided

Bart approved all three at Hard Stop 1 on 2026-10-11.

- **Mistakes. Decided:** show conflicts only. When two equal digits share a row, column or box, both are marked. It never reveals the solution and costs no points. [6]
  - Not chosen: no checking until the board is full (purest, but a full wrong board gives no clue where the error is), or checking each digit against the solution (kindest to beginners, but it rewards guessing and gives answers away).
- **Score. Decided:** level points minus hint costs during play, plus a time bonus at completion. The HUD score never ticks down with time. [9]
  - Not chosen: a score that counts down with time (more pressure, and a slow player can run out of points for hints), or level points only (simplest, but time stops mattering).
- **Hints. Decided:** a hint never fills anything in. If a placed digit is wrong, it points to it. Otherwise it marks the next logical step, explains it in one or two sentences and names its lesson. Cost is one fifth of the level's points, so five hints use up any puzzle's points. [10]
  - Not chosen: fill in one correct digit (quick, but teaches nothing), or a flat cost (simpler, but nearly free on Expert and scarce on Beginner, where hints matter most).

### Decisions

Board and input
- Selecting a cell also highlights every other cell holding the same digit. [2]
- The selected cell shows which mode is on, Place or Cross Out. [2]
- A new puzzle starts with no cell selected, in Place mode. A resumed puzzle comes back with the same cell selected and the same mode. [3]
- Taps that cannot apply do nothing (no change, no sound, no undo step): any digit or Erase on a given, Cross Out on a cell holding a digit, Erase on an empty cell, placing the digit a cell already holds. [3]
- Switching modes keeps the selected cell and is not an undo step. [3]

Candidate ring and Auto Cross
- Each candidate is open, crossed by hand, restored by hand, or crossed by Auto Cross. Restored by hand looks like open. A digit crossed by hand is drawn on top of its X, so it stays readable. [4]
- Any candidate can be crossed, all nine included. The game never judges the ring. [4]
- Erasing a digit brings the ring back with every hand mark exactly as the player left it. With Auto Cross on, its own marks match the board as it is now. [4, 5]
- Auto Cross does not change the score. [5]
- An Auto Cross X looks different from a hand X, by more than color. The senior graphic designer designs it. [5]
- Auto Cross changes are part of the undo step of the action that caused them. Turning Auto Cross on or off is not an undo step. [5]
- Show candidates (Bart, 2026-10-14): a Settings switch, on by default. Off hides every ring on the play screen and the mode toggle, so every digit tap places. A puzzle in Cross Out switches to Place, which is not an undo step. Marks are kept, Auto Cross keeps working out of sight, and a hint still shows the candidates it says to cross. Lessons always show the ring. [4.5]
- The Show candidates row sits between Sound and Auto Cross. Its line reads "Shows the candidate ring in empty cells. Off, every tap places a digit. Your marks stay." The Auto Cross row stays usable while candidates are hidden. Undo works the same while they are hidden. Hints find the same step, an elimination included, with the same text and cost. [4.5]

Play
- Undo: one step per place, replace, erase, cross or restore, with no limit, back to the start of the puzzle. Undo selects the cell it changes. The history survives closing the app. [7]
- A full board with a clash does not complete. A short message says so and the timer keeps running. [6]
- The timer runs only while the board is on screen. The pause menu hides the board. Coming back from the background opens the pause menu. [8]
- Window shapes (Bart, Phase 6): the game lays out stacked or side by side to fit the window. Side by side puts Hint at the far end from the board. Changing shape changes only the layout. [2.4]
- A window too small for a readable board shows "This window is too small. Make it bigger to play." and takes every tap. On the play screen the timer stops and the pause menu opens under the message; when the window grows, the player is on the pause menu with nothing lost. [8.1]
- Points: Beginner 100, Easy 200, Medium 400, Hard 700, Expert 1000. Hint cost: 20, 40, 80, 140, 200. [9, 10]
- Five levels: Beginner, Easy, Medium, Hard, Expert, all open from the start. [11]
- Beginner puzzles have at least 36 givens and Easy at least 32, so they look gentler. Givens still never decide the level. No symmetric givens in v1. [11]
- A hint that crosses candidates also highlights, in each target cell, the candidates to cross that still show open. [10]
- Beginner and Easy need only last empty cell, hidden single and naked single, which is what the lesson plan teaches. [11]
- No lessons for Medium and harder techniques in v1, as Bart confirmed: v1 has lessons 1 to 5. Hints explain those techniques. [11]
- Completion locks the board and shows level, time, and the score with its parts, plus a New best label when the result beats the level's previous best. [12]
- Stats are exactly the brief's list. [13]
- Every app start opens the title screen: PLAY, MENU, INFO and ABOUT (Bart, 2026-10-14), then a less prominent Buy me a coffee (Bart, 2026-10-17). MENU opens the main menu. PLAY resumes the puzzle in progress, or starts a new one at the level of the last puzzle started (Easy the first time). Back on the main menu opens the title screen. [15.0]
- Buy me a coffee, on the title screen and the About screen, hands https://buymeacoffee.com/playinc to the phone's web browser. It is the only thing in the game that opens anything outside it. The game itself never uses the network. [15.0, 15.6]
- About (Bart, 2026-10-17): copyright is held by Play, Inc. The card credits Bart Basi as designer and writer and gives bartbasi@gmail.com for questions, feedback and notices. [15.6]
- Starting a puzzle while one is in progress asks once for confirmation. The first PLAY offers lesson 1, once. [15]
- In lessons Auto Cross is off and there is no timer, score or hint. Any tap that is not the step's answer, selecting another cell included, changes nothing and gets a short explanation. Once the answer is complete, other taps are ignored until Next. [15]

### Bart's answers to the Hard Stop 1 questions

1. Reset Stats keeps lesson progress, so "lessons completed" survives a reset. [13]
2. The erase reading is confirmed: erasing a digit brings back every hand mark exactly as the player left it, and, only when Auto Cross is on, the Auto Cross marks update to match the board as it is now. [4, 5, example AC-8]
3. The "New best time" and "New best score" labels are approved and are now a rule. A label shows only when the result strictly beats the level's previous best. A tie and a level's first completion show none. [12.1, AT-67]

### Heads up

Expert puzzles (Swordfish, XYZ-Wing) may be slow to generate. Phase 2 timing is measuring it now, and the result goes to Bart at Hard Stop 2. If they are slow, the choice is a pre-built bank or fewer levels.

## Terms

- Cells: rXcY is row X (1 to 9, top to bottom) and column Y (1 to 9, left to right). Boxes are numbered 1 to 9 in reading order: box 1 top left, box 5 center, box 9 bottom right.
- Group: a row, a column or a box. There are 27.
- Peer: another cell in the same row, column or box. Every cell has 20.
- Digit: a given or a placed digit. An empty cell holds no digit.
- Ruled out: candidate d of cell C is ruled out when a peer of C holds d. A cell never rules out its own candidates.
- Ring: the nine candidate slots of a cell. The ring is the player's notes. The technique solver keeps its own candidates (section 11) and never reads the ring, except where section 10 says so.
- Reading order: r1c1, r1c2 and on to r1c9, then r2c1, and so on to r9c9.
- Nothing happens: no change on the board, no sound, no undo step.

## 2. Board, selection and highlighting

### 2.1 Board

- Standard 9 by 9 board with nine 3 by 3 boxes. Box borders read clearly heavier than cell borders.
- Givens are locked and look different from placed digits. Both show large in the center of the cell.
- Every empty cell shows its ring (section 4), unless Show candidates is off (4.5). A cell holding a digit hides its ring.

### 2.2 Selection

- Tapping any cell selects it: empty, placed or given. At most one cell is selected.
- Tapping the selected cell again keeps it selected. Tapping outside the board does not change the selection.
- The selected cell's row, column and box are highlighted.

### 2.3 Highlight states

Described by meaning. The senior graphic designer decides the look.

| State | Meaning | Shown on |
| --- | --- | --- |
| Selected | The cell the pad acts on. Also shows the mode. | The selected cell |
| Peer | Shares a group with the selected cell | Its row, column and box |
| Same digit | Holds the same digit as the selected cell | Every other cell with that digit, only when the selected cell holds a digit |
| Conflict | Holds a digit that another cell in one of its groups also holds | Every such cell, givens included (section 6) |
| Hint target | Where the hint says to place a digit or cross candidates | Section 10 |
| Hint reason | The cells that make the pattern behind the hint | Section 10 |
| Hint cross | A candidate the hint says to cross that still shows open | Ring slots of hint target cells (section 10.2) |

A cell can be in several states at once. Selected, conflict and the two hint states must stay recognizable in every combination, and never by color alone.

Decision: other cells holding the same digit as the selected cell are highlighted. This applies to cells holding the digit, not to ring slots.
- Reason: it makes scanning for hidden singles, the first technique a beginner learns, much easier.
- Example: in the hidden single example of section 11.3 (5s at r1c7, r2c5, r4c1 and r7c2), selecting r1c7 highlights the other three 5s, and the one free spot in box 1, r3c3, stands out. Selecting an empty cell shows no same-digit highlight.

Decision: the selected cell shows the current mode, so Place and Cross Out look different on the board itself, not by color alone.
- Reason: the player watches the board, not the pad. A missed mode switch places a digit where they meant to cross one.
- Example: the player selects r4c4 in Place mode and switches to Cross Out. The pad toggle and r4c4 itself both change to the Cross Out look.

### 2.4 Window shapes

Bart, Phase 6: split screen is allowed, and the game must lay out well in any window a foldable gives it (Galaxy Z Fold5 cover and inner screens, split screen on either), wide and short windows included. The device stays portrait (AT-65); only the window's shape varies.

- The game picks one of three arrangements from the window's size, by the rule and the numbers in docs/DESIGN_SYSTEM.md section 4.11. Every screen uses the same rule, so the play screen, the lessons and the menus always agree.
  - **Stacked:** the info zone (header row and band), the board, then the pad, top to bottom. This is the layout of every earlier phase.
  - **Side by side:** the board at the left; at the right a side column holding the header row, the band and the pad, top to bottom.
  - **Too small:** a message instead of the game (section 8.1).
- The game rules do not depend on the arrangement. Every control is there in both, does the same thing and has a touch area of at least 48 by 48 dp. Cells are the one exception, as in DESIGN_SYSTEM 4.4. Nothing overlaps, and no hint text, panel or message ever covers a cell.
- The 320 by 568 dp promise of Hard Stop 1 still holds: that screen is stacked (AT-66).

Decision: side by side, the header row is mirrored. Pause sits at the end next to the board, the time and score in the middle, and Hint at the far end, away from the board.
- Reason: Hint must never sit next to the board, where a finger slipping off a cell would buy a hint. That is why Hint moved away from the board in Phase 2. A slip onto Pause only pauses, which costs nothing.
- Example: Fold5 inner screen, game in the top half of a split screen (690 by 400 dp). The board is 345 dp at the left. The side column is 306 dp wide, 16 dp to the right of the board. Its header row reads, left to right: Pause, the time, the score, Hint. The hint panel, when shown, covers the side column's header row and band, never the board.

Decision: changing the window's shape during play changes only the layout. The digits, the ring, the selection, the mode, a hint on screen, the score and the undo history stay exactly as they were. The change itself never stops or resets the timer; the timer stops only where section 8 says, for example when the game loses focus to the other app in split screen, or when the window becomes too small (8.1).
- Reason: a fold or a dragged divider is not a player action, so it must not cost anything or change the puzzle.
- Example: a Hard puzzle at 3:10 on the full inner screen (stacked), r4c4 selected, Cross Out on, a Pointing hint on screen. The player opens a second app and the game becomes the top half (side by side). r4c4 is still selected, Cross Out is still on, and the same hint shows in the side column with the same highlighted candidates. If the second app took focus, the pause menu is showing at 3:10 and the timer waits for Resume (section 8).

## 3. Input model

### 3.1 Controls

Number pad 1 to 9, a mode toggle with Place and Cross Out (it always shows which is on), Erase and Undo. The Hint button is in the HUD (section 10). Erase and Undo do the same thing in both modes. With Show candidates off, the mode toggle is hidden and Place is always on (4.5).

### 3.2 Every action

| Action | Empty cell | Cell with a placed digit | Given | No cell selected |
| --- | --- | --- | --- | --- |
| Place mode, tap d | Places d. Ring hides. Undo step, sound. | Different digit: replaces it with d. Undo step, sound. Same digit: nothing happens. | Nothing happens | Nothing happens |
| Cross Out mode, tap d | Crosses candidate d, or restores it if it is crossed (section 4). Undo step, sound. | Nothing happens | Nothing happens | Nothing happens |
| Erase | Nothing happens | Removes the digit. The ring shows again (section 4). Undo step, no sound. | Nothing happens | Nothing happens |

- Undo: reverses the latest undo step wherever it was and selects that cell (section 7). No sound. Disabled when there is nothing to undo.
- Mode toggle: switches mode. The selection stays and nothing on the board changes. Not an undo step. No sound.
- Tapping a cell: selects it (section 2.2). No sound.

### 3.3 Decisions

Decision: Place and Cross Out on a given do nothing.
- Reason: givens are locked.

Decision: placing the digit a cell already holds does nothing.
- Reason: a double tap must never erase. Erase is the only way to clear a digit.

Decision: Cross Out on a cell holding a placed digit does nothing.
- Reason: its ring is hidden, and changing marks the player cannot see is confusing. Erase the digit first.

Decision: Erase on an empty cell or a given does nothing.
- Reason: the brief makes Erase clear a placed digit. Crosses are removed one at a time in Cross Out mode, so no single tap can wipe a ring.

Decision: switching modes keeps the selected cell, changes nothing on the board and is not an undo step. Undo never switches modes.

Decision: a new puzzle starts with no cell selected and Place mode on. A resumed puzzle comes back with the cell that was selected and the mode that was on when it was saved.
- Reason: a new board starts clean. A resumed board should feel as if the player never left.

Example, starting in Place mode with r2c3 empty and its ring all open:
1. Tap r2c3, tap 4: r2c3 shows 4 and the ring hides.
2. Tap 4 again: nothing happens.
3. Tap 7: r2c3 shows 7. That is one undo step.
4. Switch to Cross Out: r2c3 stays selected. Tap 1: nothing happens, because the cell holds a digit.
5. Erase: the 7 goes and the ring shows again, exactly as before step 1.
6. Tap 1: candidate 1 of r2c3 is crossed by hand.

### 3.4 Sound

The click plays when the player places or replaces a digit and when the player crosses or restores a candidate, as brief section 8 says. It does not play for erase, undo, mode switches, selection, Auto Cross changes, or when nothing happens. With sound off it never plays.

## 4. The candidate ring

### 4.1 Layout

Nine slots around the inside edge of the cell, center open. Each digit sits in the same slot in every cell. Bart picked layout A, reading rows, at Hard Stop 1: 1, 2, 3 and 4 across the top, 5 on the left and 6 on the right, 7, 8 and 9 across the bottom. The senior graphic designer owns the exact slot positions.

### 4.2 Candidate states

| State | Looks like | Set by |
| --- | --- | --- |
| Open | The digit, no X | Start of the puzzle, or Auto Cross reopening a slot it crossed |
| Crossed by hand | The digit on top of the hand X, with a thin outline | The player, in Cross Out mode |
| Restored by hand | Exactly like open | The player, in Cross Out mode |
| Crossed by Auto Cross | The digit with the Auto Cross X | Auto Cross (section 5) |

While the ring shows, a crossed digit always stays visible and readable (with Show candidates off the ring is hidden, 4.5). A digit crossed by hand is drawn on top of its X with a thin outline, so the digit reads clearly and the X still shows around it. Bart approved this at Hard Stop 1, and it replaces the brief's "X drawn over it". How the Auto Cross X differs from the hand X is in section 5.2. The senior graphic designer owns the exact drawing of both.

### 4.3 Rules

- At the start of a puzzle every slot of every empty cell is open.
- A Cross Out tap on digit d of the selected empty cell: open or restored by hand becomes crossed by hand. Crossed by hand or crossed by Auto Cross becomes restored by hand.
- The player can cross or restore any candidate: one that is ruled out, one that is not, the right answer, even all nine. The game never checks the ring.
- The player can place a digit whose candidate is crossed.
- Placing a digit hides the ring. The ring is kept underneath, and nothing the player does changes it while it is hidden.
- Erasing the digit shows the ring again. With Auto Cross off it is exactly as the player left it. With Auto Cross on, every hand mark is exactly as left and the Auto Cross marks match the board as it is now (section 5, example AC-8).

### 4.4 Worked example: Bart's example

Position B. Only these digits are on the board: r5c1 = 9 and r5c8 = 3 (row 5); r1c5 = 4 and r8c5 = 6 (column 5); r4c4 = 2, r4c6 = 4 and r6c6 = 3 (box 5). Cell X is r5c5. No digit repeats in any row, column or box.

- Row 5 rules out 9 and 3. Column 5 rules out 4 and 6. Box 5 rules out 2, 4 and 3.
- Together that is 2, 3, 4, 6 and 9. The 3 and the 4 are each ruled out twice, which changes nothing.
- The player selects X, switches to Cross Out and taps 2, 3, 4, 6 and 9. Those five show crossed by hand. 1, 5, 7 and 8 stay open. All nine digits are still visible.
- The player switches to Place and taps 8: X shows 8 and the ring hides. Erase: the ring comes back with 2, 3, 4, 6 and 9 crossed and 1, 5, 7 and 8 open.

This is acceptance test AT-14.

### 4.5 Show candidates

Bart, 2026-10-14. These are his rules; the designer decisions follow them.

- Settings has a switch, Show candidates, on by default. It is global, saved with the settings (section 14), and takes effect at once, including on a puzzle in progress. Like every setting, it is reached from the main menu and from the pause menu.
- Off, the play screen draws no candidate and no X in any empty cell, so each empty cell looks empty. The one exception is a hint's candidates to cross (below). Everything else looks exactly as it does with the switch on: givens and placed digits, the selected cell with its Place look, the peer and same digit highlights, conflicts, and the hint target and reason cells.
- Off also hides the mode toggle (Place and Cross Out). Place is the only mode, so every digit tap places, exactly as the Place mode row of 3.2 says. Erase and Undo work as usual.
- Turning it off while the puzzle in progress is in Cross Out switches that puzzle to Place, whether Settings was opened from the pause menu or from the main menu. Like any mode switch (3.3, 7.1), this keeps the selected cell, changes nothing on the board, is not an undo step and is saved (section 14). Turning Show candidates on again does not switch back: the toggle shows again with Place on.
- The ring is never cleared. Every mark of every cell stays as it is and is saved, whether the switch is on or off. Auto Cross, when it is on, keeps applying its rules out of sight (5.1). Turning Show candidates on shows every ring exactly as it is at that moment: the hand marks as the player left them, and the Auto Cross marks as Auto Cross has kept them, including changes it made while they were hidden.
- While candidates are hidden, the player cannot cross or restore anything, since Cross Out is out of reach. A hidden mark can change only through Auto Cross, or through Undo reversing an earlier cross or restore (decision below).
- Hints find the same step and cost the same, whether the switch is on or off (10.1, 10.3). When the step crosses candidates, each candidate it says to cross that still shows open (open or restored by hand) is drawn in its target cell, in its ring slot, in the hint cross look of 10.2. No other part of any ring shows. These candidates show only while the hint is on screen. A placement hint, a wrong digit hint and the fallback show no candidate.
- Turning the switch on or off while a hint is on screen keeps the hint, with no new charge. With it on, the hint shows as in 10.2; with it off, as above.
- The switch never changes the score, the timer, the stats, the undo history or completion. Turning it on or off is not an undo step and is never undone.
- Lessons always show the ring and the mode toggle, whatever the setting (15.4).

Decision: on the Settings screen the row's name is "Show candidates", and the line under its switch reads exactly: "Shows the candidate ring in empty cells. Off, every tap places a digit. Your marks stay."
- Reason: it follows the Auto Cross row: the setting's name on the switch, then one short line that says what it does and ends with a promise about the player's own work. It names the one thing that changes for the hands (taps only place) and promises that turning it off loses nothing.
- Example: a player who solves in their head turns it off, reads that their marks stay, and knows that turning it back on later brings the crosses they made earlier.

Decision: the Settings rows are, top to bottom: Sound, Show candidates, Auto Cross, Skin, Reset stats.
- Reason: Auto Cross acts on the ring, so the switch that shows or hides the ring sits right above it. Sound stays first, as before.
- Example: a player looking for Auto Cross sees Show candidates just above it and can tell the two apart from their lines.

Decision: the Auto Cross row stays usable while candidates are hidden, and it works exactly as in section 5.
- Reason: Auto Cross changes the marks the player sees when they turn candidates back on, so they may want to set it first. Greying it out would also hide a setting that is still saved and still applied.
- Example: SC-1 below.

Decision: Undo works the same while candidates are hidden. It reverses the latest step, a cross or restore included, and selects that step's cell (7.2). Only the selection shows the change; the mark itself shows when candidates are on again.
- Reason: undo reverses steps in order (7.2). Skipping cross steps while they are hidden would make the history depend on a display setting, and the same Undo press would mean different things with the switch on and off.
- Example: SC-2 below.

Decision: while candidates are hidden, a hint finds its step exactly as in 10.1, with the same text and the same cost. When the next step is an elimination, the hint shows that elimination, as Bart's rule says, even though the player cannot cross it on the hidden ring. The player keeps it in mind, or turns Show candidates on and crosses it.
- Reason: the hint stays a true logical step, the next thing the player can work out, and its text stays true. The other way, skipping eliminations silently and pointing at the next placement, would need placement texts that rest on crosses the player never saw ("every digit but 4 is ruled out here" would be false), so in practice it would say "This cell is 4", which is the fill-in hint Bart turned down at Hard Stop 1. It would also leave Bart's rule about showing the candidates to cross with nothing to do.
- Cost of this choice: a player who never crosses and asks again before anything changes gets the same step again, at full cost. That is already true with candidates showing (10.1, AT-47), and the hint stays on screen until the player closes it, so there is no need to buy it twice.
- Example: SC-3 below. A Medium player with candidates hidden pays 80 for "In this box, 7 can only go in one row. So cross 7 out in the rest of that row." and sees the 7s in that row highlighted. They keep in mind that 7 cannot go in those cells and carry on from there. Closing it and asking again before changing anything would cost another 80 and show the same step.

Decision: turning Show candidates on again leaves Place on. It does not bring back Cross Out.
- Reason: the switch to Place was a real mode switch, saved like any other. The mode toggle shows again, so Cross Out is one tap away.
- Example: in SC-1 the toggle comes back showing Place.

Worked examples. Each starts from Position B (4.4), with X = r5c5 and Y = r5c3, Show candidates on and Auto Cross off.

SC-1. Hidden marks and Auto Cross out of sight.
1. The player selects X, switches to Cross Out and crosses 2, 3, 4, 6 and 9 by hand, as in Bart's example.
2. Pause, Settings, Show candidates off, back, Resume. Every empty cell looks empty, X is still selected and shows the Place look, and the mode toggle is gone. The undo history has not grown.
3. The player taps 8: X shows 8 and the click plays. Erase: X looks empty again.
4. Pause, Settings, Auto Cross on, back, Resume. Nothing shows on the empty cells, but out of sight Auto Cross crosses every ruled out open candidate, for example 2, 3, 4 and 9 in r5c4. X's 2, 3, 4, 6 and 9 are crossed by hand, so they do not change (rule 3).
5. The player places 7 in r5c2. Out of sight, X's open 7 becomes crossed by Auto Cross.
6. Pause, Settings, Show candidates on, back, Resume. X shows 2, 3, 4, 6 and 9 crossed by hand, 7 crossed by Auto Cross, and 1, 5 and 8 open. The toggle shows again with Place on.

SC-2. Undo while hidden. In Cross Out the player crosses 1 in X, then selects Y and crosses 5 in Y. Show candidates off: the puzzle is in Place mode, no undo step added.
- Undo: Y is selected and its 5 is open again. Nothing else shows, since the rings are hidden.
- Undo: X is selected and its 1 is open again. Undo is now disabled.
- Show candidates on: every candidate of X and Y is open, and the mode is Place.

SC-3. A hint while hidden. Take the Pointing example of 10.2: the hint says to cross 7 in r5c4 to r5c9, r5c5 and r5c7 hold digits, the 7 is open in r5c4, r5c6 and r5c8 and crossed by hand in r5c9. With Show candidates off, the only small digits on the board are the 7s in r5c4, r5c6 and r5c8, in the hint cross look. r5c9 shows nothing. The hint text, the target and reason cells and the charge are the same as with the switch on. The player turns Show candidates on from the pause menu: every ring shows, the three 7s are highlighted, r5c9 shows its hand X, and the score is not charged again. If the player instead places a digit, the hint closes and the three 7s disappear.

## 5. Auto Cross

### 5.1 The rule

- A setting, off by default, in Settings, which opens from the main menu and from the pause menu. It is global and takes effect at once, including on a puzzle in progress.
- While it is on, the game keeps these three rules true for every candidate of every cell that is not a given, including rings hidden under a placed digit:
  1. An open candidate that is ruled out becomes crossed by Auto Cross.
  2. A candidate crossed by Auto Cross that is no longer ruled out becomes open.
  3. Crossed by hand and restored by hand never change.
- It applies the rules when it is turned on, after every board change and after every undo.
- It only uses the digits on the board, right or wrong. It never uses the solution and never applies any technique beyond "ruled out".
- While it is off, nothing is crossed or reopened automatically. Turning it off changes nothing on the board: its Xs stay and keep their look.
- It works the same with Show candidates off. Its marks are then out of sight until the player turns Show candidates on again (4.5).
- Rule 3 is the brief's "never changes a candidate the player crossed or restored by hand". Rule 2 is the brief's "restores only the candidates it crossed itself that nothing else on the board still rules out".

### 5.2 Decisions

Decision: Auto Cross does not change the score.
- Reason: there are no leaderboards, so the only rival is the player's own record. Auto Cross does bookkeeping the player could do by hand, and the players who need it most (small screens, tired eyes) should not pay for it.
- Alternative: halve the time bonus for any puzzle where Auto Cross was ever on. That needs one more saved flag and one more rule to explain.
- Example: the Hard example in section 9.3 scores 595 whether Auto Cross was on, off, or switched during play.

Decision: an Auto Cross X looks different from a hand X. The difference must not rely on color alone, and both must meet the 3:1 contrast rule. The senior graphic designer designs how. Restored by hand looks exactly like open.
- Reason: the player can tell their own deductions from the game's bookkeeping. That matters when they turn Auto Cross off, or tap an Auto Cross X to restore it.
- Example: after AC-1 below, X shows 1 and 9 with the hand X and 2, 3 and 4 with the Auto Cross X.

Decision: Auto Cross changes are part of the undo step of the action that caused them. Turning Auto Cross on or off is not an undo step. See 5.4.

Decision: on the Settings screen, the line under the Auto Cross switch reads exactly: "Crosses out ring digits the board rules out. Your marks stay."
- Reason: it says what rules 1 and 2 of 5.1 do, and promises rule 3, so a player can turn it on mid-puzzle without worrying about their own work. "Ring" and "rule out" are words the lessons teach.
- Example: in AC-1 the player turns it on with 1 and 9 crossed by hand and 6 restored by hand in X. All three stay exactly as they were.

### 5.3 Worked examples

Start from Position B (section 4.4) with Auto Cross off. X = r5c5, Y = r5c3, Z = r1c2. Each example continues from the one before, except AC-8.

AC-1. Turning it on mid-puzzle with hand marks. In X the player crosses 9 and 1 by hand, then crosses 6 and restores it. Then the player turns Auto Cross on.
- X: 1 and 9 stay crossed by hand. 1 is not even ruled out; that was the player's call. 2, 3 and 4 become crossed by Auto Cross. 6 stays open because it was restored by hand, even though r8c5 rules it out. 5, 7 and 8 stay open.
- Every other empty cell gets its ruled-out candidates crossed by Auto Cross. For example r5c4 gets 2, 3, 4 and 9.

AC-2. Placing a digit. The player places 7 in r5c2.
- Every open 7 in row 5, column 2 and box 4 becomes crossed by Auto Cross, including in X, Y and Z.
- No hand mark changes. The placement and all of these crosses are one undo step.

AC-3. Replacing a digit. The player replaces the 7 in r5c2 with 8.
- No 7 is left on the board, so the 7s Auto Cross crossed in X, Y and Z become open.
- 8 is now ruled out in X, Y and Z, so their open 8s become crossed by Auto Cross.
- All of this is one undo step.

AC-4. Erasing while another digit still rules the candidate out. The player places 8 in r2c5. That is in column 5, so it also rules out 8 in X. Then the player erases the 8 in r5c2.
- X: 8 stays crossed by Auto Cross, because r2c5 still rules it out.
- Y and Z: 8 becomes open, because nothing else rules it out there.

AC-5. A candidate restored by hand. X's 2 is crossed by Auto Cross, because r4c4 rules it out. The player taps 2 in Cross Out mode, so it becomes restored by hand and shows open. Then the player places 2 in r5c9, which rules it out a second time.
- X: 2 stays open. Auto Cross never crosses it again. Only the player can, with another tap.

AC-6. A candidate crossed by hand. X's 5 is open. The player crosses it by hand, then places 5 in r9c5 and erases it again.
- X: 5 stays crossed by hand the whole time. Auto Cross does not reopen it after the erase.

AC-7. Turning it off and on again. The player turns Auto Cross off. Nothing on the board changes, and the Auto Cross Xs keep their look. Then the player erases the 8 in r2c5.
- X: 8 stays crossed by Auto Cross, because nothing reopens candidates while Auto Cross is off.
- The player turns Auto Cross on again. No 8 is left on the board, so X's 8 becomes open. X's 2 (restored by hand) and 5 (crossed by hand) do not change.

AC-8. A ring hidden under a digit. Start again from Position B, with Auto Cross on from the start, so X shows 2, 3, 4, 6 and 9 crossed by Auto Cross. The player crosses 1 by hand, places 5 in X, places 7 in r5c2, then erases the 5 in X.
- X's ring: 1 crossed by hand, exactly as left. 2, 3, 4, 6 and 9 crossed by Auto Cross, as before. 7 now crossed by Auto Cross, because r5c2 holds 7. 5 and 8 open.
- The same steps with Auto Cross off throughout: the ring comes back exactly as left, with 1 crossed by hand and every other digit open, 7 included.

Wrong digits. Auto Cross trusts every digit. A wrong 7 crosses the 7s around it, possibly the right one too. Erasing it reopens them unless another digit still rules them out.

### 5.4 Auto Cross and undo

- An undo step records the digit change and every candidate the action changed, including Auto Cross changes.
- Undo puts all of them back exactly, even if Auto Cross was turned off since. Then, if Auto Cross is on, rules 1 and 2 run again.
- Turning Auto Cross on or off is not an undo step and is never undone. The crosses made by turning it on belong to no undo step.

Examples, each starting from Position B:
- U-1. Auto Cross on. Place 7 in r5c2, so the 7s in X, Y and Z are crossed by Auto Cross. One undo: r5c2 is empty and those 7s are open again.
- U-2. Auto Cross on. Place 7 in r5c2. Turn Auto Cross off. Undo: r5c2 is empty and the 7s in X, Y and Z are open again, because undo reverses everything that placement did.
- U-3. Auto Cross off. Place 7 in r5c2. Turn Auto Cross on, so the 7s in X, Y and Z are crossed by Auto Cross. Undo: r5c2 is empty, then Auto Cross runs and those 7s become open.
- U-4. Auto Cross off. Place 7 in r5c2. Turn Auto Cross on, then off. Undo: r5c2 is empty, but the 7s in X, Y and Z stay crossed by Auto Cross. Turning it on made them, not the placement, and Auto Cross is off now. Turning it on again opens them.
- U-5. Auto Cross on. X's 2 is crossed by Auto Cross. The player taps it, so it is restored by hand. Undo: X's 2 is crossed by Auto Cross again.

## 6. Mistakes

Decision (approved by Bart at Hard Stop 1): show conflicts only.

### 6.1 What the player sees

- A conflict is two or more cells in one row, column or box holding the same digit. Every one of those cells shows the conflict state, givens included.
- Placing a clashing digit is allowed. The conflict shows at once and clears as soon as the clash is gone, by erase, replace or undo.
- During play the game never compares a digit with the solution (hints aside, section 10). A wrong digit that clashes with nothing looks like any other placed digit.
- Conflicts never cost points.
- Example: r1c3 holds a given 5. The player places 5 in r1c8, and both show the conflict state. The player also places 5 in r2c2. It clashes with r1c3 in box 1, so r1c3, r1c8 and r2c2 all show it. Erasing r1c8 clears r1c8 only. r1c3 and r2c2 still clash.

### 6.2 Why

| Option | For | Against |
| --- | --- | --- |
| No checking until full | Purest. The player owns every step. | A full wrong board gives no clue where the error is. One early slip can waste a long puzzle. |
| Conflicts only (chosen) | Catches typos and clashes the player could have seen. Never reveals the solution. Fits a game about ruling things out. | A wrong digit that clashes with nothing can stay hidden for a long time. |
| Check against the solution | Kindest to beginners | Invites trying digits until one is not marked. Gives answers away for free. Needs a penalty to stay fair. |

### 6.3 A full board that is wrong

- Every puzzle has exactly one solution, so a full board with no conflict is always that solution. A full wrong board therefore always shows at least one conflict.
- When a placement fills the last empty cell and a conflict exists: the puzzle does not complete, the timer keeps running, and a short message says "The board is full, but some digits clash. Fix the marked cells." The message closes at the player's next action.
- The puzzle completes the moment the board is full with no conflict (section 12).

## 7. Undo

### 7.1 What one undo step is

One of these player actions, together with every Auto Cross change it caused (section 5.4):
- placing a digit in an empty cell
- replacing a digit
- erasing a digit
- crossing a candidate
- restoring a candidate

Not undo steps: selecting a cell, switching modes (including the switch to Place when Show candidates is turned off, 4.5), taps where nothing happens, buying a hint, turning Auto Cross or Show candidates on or off, pausing.

### 7.2 Behavior

- Undo reverses the latest step exactly. Pressing it again goes further back, all the way to the start of the puzzle. There is no limit and no redo.
- Undo selects the cell whose action it reverses, so the player sees what changed. It never changes the mode.
- Undo closes a hint that is on screen. It never refunds a hint and never changes the timer.
- The Undo button is disabled when there is nothing to undo.
- Only a placement or a replacement can complete a puzzle. Undo cannot, because every full board without a clash completed the moment it was reached.

Example across mode switches, with empty cells E, F and G. Place mode: place 5 in E. Switch to Cross Out: cross 2 in F. Switch to Place: place 7 in G. Then:
- Undo: G is empty and selected. Mode stays Place.
- Undo: F's 2 is open and F is selected. Mode stays Place.
- Undo: E is empty and selected. Undo is now disabled.

### 7.3 Undo after closing the app

Decision: undo history survives closing the app. It is saved with the puzzle in progress and deleted when the puzzle is completed or abandoned.
- Reason: Android can close the app at any time, for a phone call or low memory. Losing undo after an interruption the player did not choose would feel like a bug. The history is small.
- Example: the player places 5 in E and crosses 2 in F, then a phone call pushes the game out and Android closes it. The player reopens the app and taps PLAY on the title screen. Undo restores F's 2, then empties E.

## 8. Timer and pause

- The timer starts at 0:00 when a new puzzle's board first appears. Time spent generating the puzzle is not counted.
- It runs only while the puzzle screen is showing with nothing over the board. The hint panel and the full board message do not stop it.
- It pauses while the pause menu is open (including Settings opened from it), while the app is in the background or has lost focus, while the window is too small (8.1), and while the player is on any other screen (title, Info, About, main menu, lessons, stats) with a puzzle in progress.
- When the app comes back from the background during a puzzle, the pause menu is showing. The timer resumes when the player taps Resume.
- Android Back on the puzzle screen opens the pause menu. Back in the pause menu resumes, except while the window is too small (8.1).
- It stops for good at completion.
- It counts whole seconds, shown as m:ss, or h:mm:ss from one hour. The final time t is the whole seconds at completion.
- It is saved with the puzzle. After a restart it continues from the saved value. Time while the app is closed never counts.

Decision: the pause menu covers the board.
- Reason: paused time should not be thinking time.
- Example: at 4:12 the player opens the pause menu, studies nothing because the board is hidden, and resumes at 4:12.

### 8.1 A window that is too small

Decision: when the window is too small for a readable board, the game shows a message instead of squeezing the board. DESIGN_SYSTEM 4.11 gives the exact test: the window's content box is under 264 dp tall, or the largest board it allows, stacked or side by side, is under 240 dp. The message reads exactly:

"This window is too small. Make it bigger to play."

- Reason: a board under 240 dp has candidates too small to read or tap. A short message that says what to do is better than a board nobody can use. The wording is plain, names the problem and the fix, and fits every screen, not only the play screen.
- Windows that are too small on the Fold5 (DESIGN_SYSTEM 4.11 table): the top or bottom half of the cover screen (344 by 430 dp), the inner screen one third wide (230 by 829 dp), and the inner screen's bottom third (690 by 276 dp).

Rules:
- The message covers every screen, full screen, and takes every tap. Nothing on it can be tapped, and a tap on it changes nothing underneath and plays no sound.
- On the play screen, the moment the window becomes too small: the timer stops and the pause menu opens under the message, exactly as when the app loses focus (section 8). The puzzle is saved, as on focus loss.
- Nothing is lost. Every digit, every ring mark, the selection, the mode, a hint on screen, the score, the undo history and the timer's value stay as they were. On other screens the state underneath stays too: a lesson stays on its step, a dialog stays open with nothing chosen, Settings keeps what was set.
- When the window grows back to stacked or side by side, the message goes and the screen underneath shows as it was left. On the play screen that is the pause menu (or Settings, if the player had opened it from the pause menu before the window shrank), so the puzzle comes back paused. The timer runs again only when the player taps Resume.
- A puzzle that is being made when the window becomes too small opens paused, with the timer at 0:00, as when the app loses focus while a puzzle is made. Its level's Started goes up when its board first appears, under the pause menu, as usual (section 13).
- Android Back while the message shows: in the pause menu it does nothing. Everywhere else it does what it does on the screen underneath.
- Reason for the Back rule: Back in the pause menu resumes play. Under the message that would start the clock on a board the player cannot see, and the player would come back to a running timer instead of the pause menu.
- The message and the arrangement are never saved. They come from the window each time the game lays out.

Example: a Medium puzzle at 6:20 on the full cover screen. The player opens split screen with the game in the top half of the cover screen (344 by 430 dp). The message shows and the timer stops at 6:20. The player taps the message three times and presses Back: nothing changes. Two minutes later the player drags the divider down until the game has the whole cover screen again. The message is gone, the pause menu is showing at 6:20, and after Resume the timer runs on from 6:20 with the board exactly as it was.

## 9. Score

Decision (approved by Bart at Hard Stop 1): the score is the level's points minus hint costs, shown live in the HUD, plus a time bonus added at completion.

### 9.1 Numbers

| Level | Points B | Par time P | Hint cost H (B divided by 5) |
| --- | --- | --- | --- |
| Beginner | 100 | 8:00 (480 s) | 20 |
| Easy | 200 | 12:00 (720 s) | 40 |
| Medium | 400 | 20:00 (1200 s) | 80 |
| Hard | 700 | 30:00 (1800 s) | 140 |
| Expert | 1000 | 45:00 (2700 s) | 200 |

The par times are a first guess. Phase 4 play should tune them.

### 9.2 Formula

- During play the HUD shows S = B minus H times n, where n is the number of hints bought. S does not change with time.
- S never goes below zero, because a hint can only be bought when S is at least H (section 10).
- At completion, with final time t in whole seconds, the time bonus is T = floor(B times (P minus t) divided by P) when t is less than P, and 0 otherwise.
- The final score is F = S + T. It becomes final at completion and never changes after that. An abandoned puzzle has no final score.
- Conflicts never cost points. Auto Cross never changes the score.

### 9.3 Worked examples

| Puzzle | Time | Hints | S | T | Final F |
| --- | --- | --- | --- | --- | --- |
| Easy | 9:00 (540 s) | 1 | 200 minus 40 = 160 | floor(200 times 180 / 720) = 50 | 210 |
| Medium | 25:00 (1500 s) | 0 | 400 | over par, 0 | 400 |
| Medium | 15:00 (900 s) | 1 | 400 minus 80 = 320 | floor(400 times 300 / 1200) = 100 | 420 |
| Hard | 22:30 (1350 s) | 2 | 700 minus 280 = 420 | floor(700 times 450 / 1800) = 175 | 595 |
| Beginner | 7:00 (420 s) | 5 | 100 minus 100 = 0 | floor(100 times 60 / 480) = floor(12.5) = 12 | 12 |

### 9.4 Why

- Level points reward harder puzzles.
- The HUD score only moves when the player buys a hint, so it reads as a hint budget and adds no clock pressure to a calm game.
- The time bonus rewards speed without ever eating into the hint budget.
- Alternatives: a score that counts down with time adds pressure, and a slow player, who needs hints most, runs out of points for them. Level points only is simplest, but then time does not matter at all.

## 10. Hints

Decision (approved by Bart at Hard Stop 1): a hint never changes the board. It points out a wrong digit if there is one; otherwise it shows the next logical step.

### 10.1 What a hint finds

When the player taps Hint:
1. Wrong digit. If any placed digit differs from the solution, the hint marks the first such cell in reading order as the target and says "This {d} is not right. Erase it and look again."
2. Next step. Otherwise every digit on the board is correct. The technique solver (section 11) starts from those digits with its own candidates and works step by step in its fixed order. The hint is the first step that changes something the player has not done yet:
   - a placement, which is always new because the cell is empty, or
   - an elimination where at least one candidate it removes still shows open (or restored by hand) on the player's ring.
   Steps whose eliminations are all crossed on the ring already are applied silently, and the search goes on.
3. Fallback. If the solver finds no step, which should never happen for a graded puzzle, the hint marks the first empty cell in reading order and says "This cell is {d}."

The solver reads the ring only for the "already done" check in step 2. Wrong crosses on the ring never mislead a hint.

### 10.2 What the player sees

- Target cells: the cell to fill, or the cells where a candidate should be crossed and still shows open. Reason cells: the cells that make the pattern (table below).
- One or two plain sentences, the technique name, and for Beginner and Easy techniques the lesson title, for example "Lesson: Hidden single".
- The hint never changes the board, the selection or the mode. It is not an undo step.
- It stays on screen until the player closes it, places, replaces or erases a digit, or uses undo. Crossing and restoring do not close it, so the player can carry out an elimination.
- While a hint is on screen the Hint button is disabled. A hint that was closed and asked for again costs again.
- A hint on screen is saved with the puzzle and shows again on resume, with no new charge.

Candidates to cross (Bart, Hard Stop 2):
- When the step crosses candidates, the board also highlights, in each target cell, every candidate the step says to cross that still shows open (open or restored by hand). For a hidden pair or triple these are the other digits in the target cells.
- A candidate the step crosses that is already crossed, by hand or by Auto Cross, is drawn as usual.
- The highlight follows the ring while the hint is on screen: crossing a highlighted candidate removes its highlight, and restoring it brings the highlight back.
- A placement step, a wrong digit hint and the fallback highlight no candidate.
- The highlight goes away when the hint closes, and shows again with the hint on resume.
- With Show candidates off, the highlighted candidates are the only part of any ring that shows, and only while the hint is on screen (4.5, example SC-3).
- The senior graphic designer decides the look.
- Example: a Pointing hint says to cross 7 in row 5 outside box 4, that is r5c4 to r5c9. r5c5 and r5c7 hold other digits. The 7 is open in r5c4, r5c6 and r5c8, and the player crossed it by hand in r5c9. The targets are r5c4, r5c6 and r5c8, and the 7 is highlighted in each. r5c9 shows its hand X as usual. The player crosses 7 in r5c4: that highlight goes, the hint stays, and 7 stays highlighted in r5c6 and r5c8.

In the texts below, {group} is "row", "column" or "box", and the reason or target cells show which one.

| Technique | Reason cells | Target cells | Text |
| --- | --- | --- | --- |
| Wrong digit | None | The wrong cell | This {d} is not right. Erase it and look again. |
| Last empty cell | The other cells of the group | The empty cell | This {group} has one empty cell left. It must be {d}. |
| Hidden single | The cells holding {d} that rule out the group's other empty cells | The cell | In this {group}, {d} fits in only one cell. It goes here. |
| Naked single | None | The cell | Every digit but {d} is ruled out here, so this cell is {d}. |
| Pointing | The box cells where {d} can go | Cells to cross | In this box, {d} can only go in one {row or column}. So cross {d} out in the rest of that {row or column}. |
| Claiming | The row or column cells where {d} can go | Cells to cross | In this {row or column}, {d} can only go in one box. So cross {d} out in the rest of that box. |
| Naked pair | The two cells | Cells to cross | These two cells can only hold {a} and {b}. So cross {a} and {b} out in the rest of this {group}. |
| Hidden pair | None | The two cells | In this {group}, {a} and {b} can only go in these two cells. So cross out every other digit in them. |
| Naked triple | The three cells | Cells to cross | These three cells can only hold {a}, {b} and {c}. So cross those digits out in the rest of this {group}. |
| Hidden triple | None | The three cells | In this {group}, {a}, {b} and {c} can only go in these three cells. So cross out every other digit in them. |
| X-Wing | The four cells | Cells to cross | In these two rows, {d} can only go in the same two columns. So cross {d} out in the rest of those columns. (Swap rows and columns as needed.) |
| Y-Wing | The pivot and two wings | Cells to cross | The middle cell is {x} or {y}, so one of the other two marked cells must be {z}. Cross {z} out in cells that see both. |
| Swordfish | The pattern cells | Cells to cross | In these three rows, {d} can only go in the same three columns. So cross {d} out in the rest of those columns. (Swap rows and columns as needed.) |
| XYZ-Wing | The pivot and two wings | Cells to cross | One of these three cells must be {z}. So cross {z} out in cells that see all three. |

### 10.3 Cost

Decision: the cost is scaled to the level: one fifth of the level's points (table in 9.1).
- Reason: five hints use up the points at any level, so a hint costs the same share of the reward everywhere. A flat cost of 50 would buy 20 hints on Expert and only 2 on Beginner, the opposite of where help is needed.
- Easy example: the HUD shows 200. One hint costs 40, and the HUD shows 160.
- Medium example: the HUD shows 400. Two hints cost 160, and the HUD shows 240.
- Hard example: the HUD shows 700. One hint costs 140, and the HUD shows 560.

### 10.4 When the Hint button is disabled

- When the score is below the hint cost. The score only changes by whole hints, so this happens exactly when the score is 0, after five hints.
- While a hint is on screen.
- When the puzzle is complete. Lessons have no Hint button.

A disabled Hint button looks disabled. Tapping it does nothing: no charge, no hint, no sound. The score stays where it is.

### 10.5 Alternatives

- Fill in one correct digit: one tap, but it teaches nothing and skips the reasoning the game is built around.
- Show the step and also apply it: saves taps, but the player watches instead of doing.

## 11. Levels and techniques

### 11.1 Grading

- The technique solver starts from the givens. Its candidates for an empty cell are the digits not ruled out, minus any it has eliminated. It never reads the player's ring.
- It repeats: try each technique in the order of 11.3, apply the first step found, then start again from the first technique.
- A step is one placement, or one pattern with all the eliminations it allows. An elimination step only counts if it removes at least one candidate.
- A placement fills the cell and removes that digit from its peers' candidates.
- If the solver fills the board, the puzzle's level is the level that introduces the hardest technique it used. If it gets stuck, the puzzle has no level and is never offered.
- The number of givens is never part of grading.
- The search order is fixed, so the same board always gives the same steps and the same hint. Default order: groups as boxes 1 to 9, then rows 1 to 9, then columns 1 to 9; cells in reading order; digits 1 to 9; for X-Wing and Swordfish, rows before columns. The puzzle engine developer may refine the order inside a technique but must keep it fixed and documented.

### 11.2 Levels

| Level | Needs at least one of | Also allows | Lessons |
| --- | --- | --- | --- |
| Beginner | Hidden single | Last empty cell | Lesson: Last empty cell; Lesson: Hidden single |
| Easy | Naked single | All Beginner techniques | Lesson: Naked single, plus the Beginner lessons |
| Medium | Pointing, Claiming, Naked pair | All Easy techniques | None in v1 |
| Hard | Hidden pair, Naked triple, Hidden triple, X-Wing, Y-Wing | All Medium techniques | None in v1 |
| Expert | Swordfish, XYZ-Wing | All Hard techniques | None in v1 |

A puzzle at a level uses at least one technique from "Needs at least one of", and nothing from a higher level. Last empty cell is allowed everywhere and needed nowhere. All five levels are open from the start.

Decision: five levels, named Beginner, Easy, Medium, Hard and Expert.
- Reason: Beginner and Easy split the three singles, so a new player gets two gentle steps, each backed by lessons. Medium, Hard and Expert follow the usual order of human techniques. Five keeps each step noticeable without thin levels.
- Example: a puzzle the solver finishes with hidden singles only is Beginner. If it ever needs a naked single, it is Easy. If it ever needs pointing, it is Medium.

Decision: hidden single is a Beginner technique and naked single an Easy one.
- Reason: a hidden single is found by scanning one box for one digit, with no notes. It is the classic first technique. A naked single needs every digit checked for one cell, which is where the candidate ring earns its place, so it marks the step up to Easy.
- Example: see techniques 2 and 3 below.

Decision: no lessons for Medium and harder techniques in v1. Bart confirmed this at Hard Stop 1: v1 ships lessons 1 to 5 only, and the Medium lessons that docs/LESSONS.md section 5 suggests are not in v1.
- Reason: lessons are for beginners, the brief requires only the techniques of the two easiest levels, and the hint explains each harder technique in place when the player meets it. Lessons for the Medium techniques are a good candidate for a later version.
- Example: a Medium player who asks for a hint on a pointing step sees "In this box, 7 can only go in one row. So cross 7 out in the rest of that row." with the technique name Pointing and no lesson title.

The lesson titles above are the ones LESSONS.md must use, so hints and levels can name them.

### 11.3 Techniques

In order from easiest. "Candidate" here means the solver's candidate. Every example board below was checked by hand: no digit repeats in any row, column or box.

1. **Last empty cell** (Beginner)
   - Pattern: a group with exactly one empty cell.
   - Conclusion: place the one digit the group is missing.
   - Example: row 3 holds 1, 2, 3, 4, 5, 6, 8 and 9, and r3c7 is empty. r3c7 is 7.
2. **Hidden single** (Beginner)
   - Pattern: a group and a digit d not yet in it, where exactly one empty cell of the group has d as a candidate.
   - Conclusion: place d in that cell.
   - Example: 5s at r1c7, r2c5, r4c1 and r7c2, and box 1 empty. Rows 1 and 2 rule out 5 in the top two rows of box 1. Columns 1 and 2 rule out r3c1 and r3c2. Only r3c3 is left, so r3c3 is 5.
3. **Naked single** (Easy)
   - Pattern: an empty cell with exactly one candidate.
   - Conclusion: place that digit.
   - Example: Position B plus r5c9 = 1, r2c5 = 5 and r9c5 = 7. X (r5c5) has 1, 2, 3, 4, 5, 6, 7 and 9 ruled out, so X is 8.
4. **Pointing** (Medium)
   - Pattern: in a box, every cell with candidate d lies in one row (or one column), and d is still a candidate in that row (column) outside the box.
   - Conclusion: remove d from those cells outside the box.
   - Example: box 4 holds 1, 2 and 3 in r4c1 to r4c3 and 4, 5 and 6 in r6c1 to r6c3. Its 7 must go in r5c1, r5c2 or r5c3, all in row 5. So 7 is removed from r5c4 to r5c9.
5. **Claiming** (Medium)
   - Pattern: in a row (or column), every cell with candidate d lies in one box, and d is still a candidate in that box outside the row (column).
   - Conclusion: remove d from those cells of the box.
   - Example: row 1 holds 1, 2, 4, 5, 6 and 7 in r1c4 to r1c9. Its 3 must go in r1c1, r1c2 or r1c3, all in box 1. So 3 is removed from rows 2 and 3 of box 1.
6. **Naked pair** (Medium)
   - Pattern: two empty cells in one group whose candidates are exactly the same two digits a and b.
   - Conclusion: remove a and b from every other cell of every group both cells share.
   - Example: r9c1 and r9c2 both have only 2 and 9. Remove 2 and 9 from the rest of row 9 and the rest of box 7.
7. **Hidden pair** (Hard)
   - Pattern: in one group, two digits a and b, neither yet in the group, that are candidates in exactly the same two cells of the group and in no other cell of it.
   - Conclusion: remove every other candidate from those two cells.
   - Example: in column 4, 1 and 8 appear only in r2c4 (1, 3, 8) and r7c4 (1, 5, 8, 9). Remove 3 from r2c4, and 5 and 9 from r7c4.
8. **Naked triple** (Hard)
   - Pattern: three empty cells in one group whose candidates together are exactly three digits a, b and c. Each cell has two or three of them.
   - Conclusion: remove a, b and c from every other cell of every group all three cells share.
   - Example: in row 2, r2c1 has 4 and 6, r2c5 has 6 and 9, r2c8 has 4 and 9. Remove 4, 6 and 9 from the rest of row 2.
9. **Hidden triple** (Hard)
   - Pattern: in one group, three digits a, b and c, none yet in the group, whose candidate cells in the group are exactly three cells together.
   - Conclusion: remove every other candidate from those three cells.
   - Example: in box 9, 2, 5 and 7 appear only in r7c7 (2, 5, 6), r8c9 (1, 5, 7) and r9c8 (2, 4, 7). Remove 6 from r7c7, 1 from r8c9 and 4 from r9c8.
10. **X-Wing** (Hard)
    - Pattern: a digit d and two rows in which d is a candidate in exactly two cells each, and those four cells lie in the same two columns. Or the same with rows and columns swapped.
    - Conclusion: remove d from every other cell of those two columns (or rows).
    - Why it works: each row's d is in one of the two columns, and the two rows cannot use the same column, so both columns get their d from these two rows.
    - Example: in rows 2 and 7, 4 is a candidate only in r2c3, r2c8, r7c3 and r7c8. Remove 4 from the rest of columns 3 and 8.
11. **Y-Wing** (Hard)
    - Pattern: a pivot cell with exactly two candidates x and y. Two wing cells that each share a group with the pivot: one with exactly x and z, the other with exactly y and z, where z is a third digit.
    - Conclusion: remove z from every cell, other than the wings, that shares a group with both wings.
    - Why it works: if the pivot is x, the first wing is z. If the pivot is y, the second wing is z.
    - Example: pivot r5c5 (2, 7), wings r5c1 (2, 5) and r2c5 (5, 7). Only r2c1 sees both wings, through column 1 and row 2. Remove 5 from r2c1.
12. **Swordfish** (Expert)
    - Pattern: a digit d and three rows in which d is a candidate in two or three cells each, and all those cells lie in the same three columns. Or the same with rows and columns swapped.
    - Conclusion: remove d from every other cell of those three columns (or rows).
    - Example: in rows 1, 4 and 8, 6 is a candidate only in r1c2, r1c9, r4c2, r4c5, r8c5 and r8c9, which are columns 2, 5 and 9. Remove 6 from the rest of columns 2, 5 and 9.
13. **XYZ-Wing** (Expert)
    - Pattern: a pivot cell with exactly three candidates x, y and z. Two wing cells that each share a group with the pivot: one with exactly x and z, the other with exactly y and z.
    - Conclusion: remove z from every cell, other than these three, that shares a group with the pivot and with both wings.
    - Why it works: whatever the pivot is, the pivot or one of the wings is z.
    - Example: pivot r5c5 (2, 5, 7), wings r5c4 (2, 5) and r2c5 (5, 7). Only r4c5 and r6c5 see all three. Remove 5 from both.

### 11.4 Number of givens

Decision (Bart, Hard Stop 2): a generated Beginner puzzle has at least 36 givens and a generated Easy puzzle at least 32. Medium, Hard and Expert have no floor.
- Reason: more digits make the two easiest levels look gentler, without changing what the player needs to know.
- How: the generator stops removing givens once the puzzle is down to its level's floor. Everything else stays: the puzzle has exactly one solution and grades at exactly its level (11.1, 11.2), so a Beginner puzzle still needs a hidden single and an Easy puzzle still needs a naked single. An attempt that misses its level is dropped and the next one starts, as before.
- The number of givens is still never part of grading. The floor only limits how far removal goes.
- No symmetric pattern of givens in v1.
- Lesson boards are hand made (docs/LESSONS.md) and have no floor.
- Why these numbers: today every level averages about 25 givens (docs/GENERATION_TIMING.md). 36 and 32 give clear steps of about 4 and 7 givens above the harder levels. With 45 empty cells, last empty cell alone almost never finishes a board, so nearly every Beginner attempt still needs a hidden single and Beginner keeps its hit rate of about 100%. More givens leave more hidden singles, so fewer Easy attempts need a naked single and Easy's hit rate (46% today) will fall. At about 25 ms per attempt on the laptop, even 1 hit in 10 means about a quarter second per puzzle, well inside the Beginner to Hard waits Bart accepted.
- Example: a Beginner attempt removes givens in random order until 36 are left and stops. The solver finishes it with last empty cells and hidden singles, using at least one hidden single, so it is kept. An Easy attempt stops at 32 givens; if the solver finishes it without ever needing a naked single, it grades Beginner, so it is dropped.

## 12. Completion

- The puzzle completes the moment a placement or replacement leaves every cell filled with no conflict.
- At that moment, in this order: the timer stops; the board locks (no input, Undo and Hint disabled, any hint closes); the final score is computed (section 9); the New best labels are decided (12.1); stats update and are saved (section 13); the saved puzzle and its undo history are deleted; the completion screen shows.
- The completion screen shows the level, the final time, the final score with its parts (points after hints, time bonus, total), the number of hints used, and any New best label (12.1). Buttons: Play again (a new puzzle at the same level, with no dialog, since nothing is in progress) and Menu.
- Example: the Hard example in 9.3 shows "Hard, 22:30, points 420, time bonus 175, score 595, 2 hints", plus any label 12.1 gives it.

### 12.1 New best labels

Rule, approved by Bart at Hard Stop 1:
- "New best time" shows when the final time t, in whole seconds, is lower than the level's best time.
- "New best score" shows when the final score F is higher than the level's best score.
- The best time and best score here are the level's stats as they stood just before this completion updated them (section 13). The labels read only these two stats, which the game already keeps. They add no stat and no saved data.
- Each label is checked on its own, so a result shows neither, one or both. Each label shows with the value it names. The senior graphic designer decides the look.

Decision: a tie is not a new best. A final time equal to the level's best time shows no "New best time", and a final score equal to its best score shows no "New best score".
- Reason: Bart's rule says the result must beat the previous best. A tie leaves the best unchanged, so a label always matches a change the player can see on the stats screen.
- Example: rows 3 and 6 of the table below.

Decision: the first completion of a level shows no label. That includes the first completion after Reset Stats, because Reset Stats clears the bests.
- Reason: with no previous best there is nothing to beat. A label on every first try would carry no news and would soon mean nothing. The stats screen still shows the result as the level's best.
- Example: row 1 of the table below.

Example: Easy (points 200, par 720 s, hint cost 40), starting with no Easy completions. Each row is one completed Easy puzzle, in order. Rows 1 and 2 are the stats example of section 13.

| # | Time | Hints | Score, S + T = F | Best time and best score before | Labels |
| --- | --- | --- | --- | --- | --- |
| 1 | 5:00 (300 s) | 1 | 160 + 116 = 276 | None yet | None: first completion |
| 2 | 6:41 (401 s) | 2 | 120 + 88 = 208 | 5:00, 276 | None |
| 3 | 5:00 (300 s) | 0 | 200 + 116 = 316 | 5:00, 276 | New best score. The time ties, so no New best time. |
| 4 | 4:50 (290 s) | 3 | 80 + 119 = 199 | 5:00, 316 | New best time |
| 5 | 4:00 (240 s) | 0 | 200 + 133 = 333 | 4:50, 316 | New best time and New best score |
| 6 | 4:01 (241 s) | 0 | 200 + 133 = 333 | 4:00, 333 | None: the score ties and the time is slower |

After row 6, if the player resets stats, the next Easy completion shows no label, whatever its time and score.

This is acceptance test AT-67.

## 13. Stats

Decision: the stats are exactly the brief's list, with no additions. The New best labels on the completion screen (12.1) only read the best time and best score kept here.
- Reason: the brief's list answers "how am I doing" per level without clutter.
- Example: after the two Easy completions of the average example below, the Easy row reads: started 2, completed 2, best time 5:00, average time 5:51, best score 276.

### 13.1 Definitions

| Stat | Definition | Empty value |
| --- | --- | --- |
| Started (per level) | Puzzles of this level whose board appeared. Includes abandoned and in-progress puzzles. | 0 |
| Completed (per level) | Puzzles of this level completed | 0 |
| Best time (per level) | Lowest final time among completed puzzles of this level | Shown as "-" until the first completion |
| Average time (per level) | Sum of the final times of completed puzzles divided by Completed, rounded to the nearest second, halves rounded up | Shown as "-" until the first completion |
| Best score (per level) | Highest final score among completed puzzles of this level. 0 is a valid best. | Shown as "-" until the first completion |
| Lessons completed (overall) | Number of different lessons finished at least once, shown as "N of M" where M is the number of lessons, 5 in v1 | 0 of M |

Stored per level: started, completed, best time, total time of completed puzzles, best score. Times show as m:ss, or h:mm:ss from one hour. All stats stay on the device.

### 13.2 When they change

| Event | Change |
| --- | --- |
| A new puzzle's board first appears | Started +1 for its level |
| A puzzle is resumed | Nothing |
| A puzzle is completed | Completed +1; total time + t; best time and best score updated if beaten. The New best labels are decided first, from the bests as they were (12.1). |
| A puzzle is abandoned | Nothing. It already counted as started. |
| A lesson is finished for the first time | Lessons completed +1 |
| Reset Stats, after confirmation | Every level's started, completed, best time, total time and best score cleared. If a puzzle is in progress, its level's Started becomes 1, so Completed never exceeds Started. Lesson progress is kept (Bart, Hard Stop 1). The next completion at each level counts as a first completion and shows no New best label (12.1). |

Reset Stats is a button in Settings. It asks "Reset all stats? This cannot be undone." with Cancel and Reset. Cancel changes nothing.

Average example: Easy completions in 300 s with 1 hint (score 160 + 116 = 276) and 401 s with 2 hints (score 120 + 88 = 208). Total 701 s, divided by 2 is 350.5 s, rounded up to 351 s, shown as 5:51.

## 14. Persistence

| What | Contents | Saved | Deleted |
| --- | --- | --- | --- |
| Puzzle in progress | Puzzle ID (reproduces the givens and the solution) and level; every placed digit; the state of every candidate of every non-given cell (the four states of 4.2); timer; score and hints bought; mode; selected cell; undo history; the hint on screen, if any | When the board first appears; after every board change and undo; after a mode switch, a hint bought or closed, and an Auto Cross change; when the app pauses, goes to the background or leaves the puzzle screen | At completion or abandon |
| Settings | Sound (default on), skin (one of the two built-in skins, Pop light or Pop dark; default Pop light), Auto Cross (default off), Show candidates (default on; 4.5), last level started (default Easy; 15.0) | When changed; the last level when a new puzzle starts being made (15.2) | Never. Reset Stats does not change them. |
| Stats | Section 13 | At puzzle start, completion and Reset Stats | Cleared by Reset Stats |
| Lesson progress | Which lessons were finished | When a lesson is finished the first time | Never |
| First launch | Whether the lesson 1 offer was answered (15.3) | When answered | Never |

- Not saved: a lesson in progress (it restarts from its first screen), which screen was showing (every app start opens the title screen, 15.0), the full board message, and the window arrangement and too small message (2.4, 8.1), which come from the window each time.
- If the app dies without warning, no board change is lost, because each one is saved at once. At most the timer seconds since the last save are lost.
- If saved data cannot be read or fails validation, that part falls back to its default (for the puzzle: none in progress), the other parts load normally, and the game does not crash.

## 15. Title screen, new puzzle, first launch and lessons

### 15.0 Title screen

Bart, 2026-10-14. These are his rules, not designer decisions.

- Every app start opens the title screen: the wordmark and the hero, then five buttons, top to bottom PLAY, MENU, INFO, ABOUT and Buy me a coffee (MENU added by Bart later on 2026-10-14, Buy me a coffee on 2026-10-17). Buy me a coffee is less prominent than the other four; the design system sets its look. An app start means the app was not running, whether the player closed it or Android did. Coming back from the background while the app is still running is not an app start: the player is back where they left, and during a puzzle the pause menu is showing (section 8).
- The title screen opens on every start, with or without a puzzle in progress and on first launch too. It has no Continue button; PLAY does that job.
- Android Back on the title screen closes the app. Everything is already saved (section 14).
- PLAY does the first of these that applies:
  1. If the lesson 1 offer has not been answered, it shows the offer (15.3).
  2. Else, if a puzzle is in progress, it opens that puzzle exactly as Continue does (15.1): the saved cell selected, the saved mode on, the timer running on from its saved value. No dialog, and stats do not change.
  3. Else it starts a new puzzle at the level of the last puzzle started, or Easy if no puzzle was ever started. The making a puzzle card shows while it is made, as for every new puzzle (DESIGN_SYSTEM 7.14), and the puzzle starts exactly as 15.2 describes: its board appears with the timer at 0:00, and its level's Started goes up by 1.
- A tap on PLAY while a puzzle is being made does nothing, so one tap never starts two puzzles.
- The last level started is the level of the last new puzzle the game began to make, from level select, from Play again or from PLAY itself. It is saved with the settings (section 14). Abandoning, completing, lessons and Reset Stats do not change it. If the saved value is missing or unreadable it is Easy.
- MENU opens the main menu (15.1), unchanged. Android Back on the main menu returns to the title screen. MENU never shows the lesson 1 offer, starts or resumes a puzzle, or changes stats or the timer; the offer stays on the first PLAY (15.3).
- INFO opens the Info screen (15.5) and ABOUT opens the About screen (15.6), each over the title screen. Back on either returns to the title screen. That means Android Back, and also the screen's own back button if the design gives it one, as other pushed screens such as Settings have.
- Buy me a coffee (Bart, 2026-10-17) hands the address https://buymeacoffee.com/playinc to the phone's web browser, which opens it. The game sends nothing itself: it does not check the network, fetch the page or add anything to the address. Nothing else happens in the game: no screen changes, no puzzle starts or resumes, stats, settings and the puzzle in progress do not change, and the lesson 1 offer stays on the first PLAY. The browser takes the screen, so the game goes to the background as it does when the player switches apps. Coming back to the game shows the title screen, as left. If Android closed the game while it was in the background, coming back is an app start and the title screen shows anyway.
- With no network, for example in airplane mode, the button works the same: it opens the browser, and the browser shows its own offline page. The game shows no message of its own. If the phone has no app that can open a web page, nothing happens.
- While a puzzle is being made, a tap on any title button, Buy me a coffee included, does nothing.
- Example: with an Easy puzzle in progress at 2:00, the player taps Buy me a coffee. The browser opens https://buymeacoffee.com/playinc. The player switches back to Sudoku: the title screen shows, and PLAY resumes the Easy puzzle at 2:00, with Easy Started unchanged.
- The main menu is unchanged (15.1). It is reached from MENU on the title screen, and from the pause menu's Menu and the completion screen's Menu, as before. Android Back on the main menu opens the title screen. This replaces the Phase 6 rule that Back on the main menu closes the app.
- Example, a new player: install, open the app, and the title screen shows. Tap PLAY: the lesson 1 offer shows. Tap Skip: a new Easy puzzle starts at 0:00 with a score of 200. Play two minutes, then tap Pause, then Menu: the main menu shows Continue. Press Back: the title screen. Tap PLAY: the same Easy puzzle, same cell and mode, timer at 2:00 and running.
- Example, MENU: with an Easy puzzle in progress at 2:00, the player launches the app and taps MENU. The main menu shows Continue, New puzzle, Lessons, Stats and Settings. The player opens Stats, presses Back twice and is on the title screen again. PLAY then resumes the Easy puzzle at 2:00.
- Example, the last level: the player completes a Hard puzzle, taps Menu on the completion screen and presses Back. On the title screen PLAY starts a new Hard puzzle. If instead the player had started a Beginner puzzle from level select and then abandoned it for a Medium one, PLAY after completing the Medium puzzle starts Medium.

### 15.1 App start and the main menu

- The app starts on the title screen (15.0), never on the main menu.
- The main menu is reached from MENU on the title screen (15.0), from the pause menu's Menu and from the completion screen's Menu. Its buttons are as before: Continue first, only when a puzzle is in progress, then New puzzle, Lessons, Stats and Settings.
- Continue opens the puzzle in progress with the saved cell selected, the saved mode on and the timer running.
- Android Back on the main menu opens the title screen (15.0).

### 15.2 Starting a new puzzle

- New puzzle opens level select: five levels, all open.
- Every new puzzle, from level select, Play again or PLAY, becomes the last level started (15.0) when it starts being made.
- With no puzzle in progress, the chosen level starts at once, after generation.
- With a puzzle in progress, a dialog asks: "You have a {level} puzzle in progress. Start a new {chosen level} puzzle? The current one will count as started, not completed." Buttons: Keep playing and Start new.
- Keep playing returns to the puzzle in progress with nothing changed.
- Start new abandons the old puzzle: it and its undo history are deleted and stats do not change. Then the new puzzle is generated, and when its board appears its level's Started goes up by 1.
- Play again on the completion screen starts a new puzzle at the same level with no dialog.

### 15.3 First launch

- The offer no longer shows at app start. It shows the first time the player taps PLAY on the title screen (15.0): "New to Sudoku? Lesson 1 shows you how to play." Buttons: Start lesson and Skip.
- Start lesson opens lesson 1, as before: the lesson opens over the main menu, so leaving the lesson shows the main menu.
- Skip goes straight into a puzzle, exactly like PLAY with the offer answered: the puzzle in progress if there is one, else a new puzzle at the last level started (Easy the first time).
- Either answer is final, and the offer never shows again. If the app closes before the player answers, the next PLAY shows it again.
- Decision: Android Back on the offer returns to the title screen and does not answer it, so the next PLAY shows it again.
  - Reason: this matches Bart's Phase 6 rule for the "Start a new puzzle?" dialog, where Back means no choice was made, and the rule above that an unanswered offer shows again.
  - Example: fresh install, PLAY, then Back: the title screen. PLAY again: the offer shows again.
- Lesson 1 is always available from the Lessons screen.

### 15.4 Lessons and the game rules

LESSONS.md holds the lesson content. These rules apply to every lesson:
- Lessons use the same board, selection, Place and Cross Out modes and Erase as puzzles.
- Auto Cross is always off in lessons, whatever the setting, because lessons teach crossing by hand.
- Lessons always show the ring and the mode toggle, whatever the Show candidates setting (Bart, 2026-10-14). The setting is kept as it is and applies again on the play screen.
- No timer, score, hints or puzzle stats in lessons. A puzzle in progress stays saved and untouched, and its timer does not run.
- Until the step's answer is complete, every tap that is not part of it, as LESSONS.md defines it, is a wrong tap. That includes selecting a different cell. A wrong tap changes nothing (board, ring, selection and mode stay as they were), the lesson's short explanation shows, and the player tries again. The player cannot fail.
- Reason: lessons are scripted around one cell, so this keeps the player on the taught cell and makes every tap teach.
- Once the step's answer is complete, the praise line and Next show. Every other tap on the board, the pad and the controls is ignored, with no text, until the player taps Next.
- Reason: a wrong tap text is written for the step in progress. After the answer it would be out of date, for example "Pick the cell first" once the digit is already placed.
- A lesson counts as finished when the player completes its last step. Leaving early does not count.
- Example: in the candidate ring lesson, on Bart's example, the player in Cross Out mode taps 5. 5 stays open, a short note explains that nothing in the row, column or box holds a 5, and the step waits for the right taps.

### 15.5 Info screen text

The Info screen (INFO on the title screen) shows exactly the text below, in this order. Each heading in bold is a heading on screen. Each paragraph shows as written, and each line starting with a dash shows as its own line in a list. The text scrolls when it does not fit. Every fact in it matches the section named in brackets after each heading; those brackets are for the team and do not show on screen. If one of those sections changes, this text changes with it.

**How to play** [2, 6.3, 11]

Fill the board so that every row, every column and every box holds the digits 1 to 9, each exactly once. A box is one of the nine 3 by 3 squares with the heavier borders.

Every puzzle has exactly one answer, and you can always reach it by reasoning. You never need to guess.

Tap PLAY to start. It brings back the puzzle you were playing, or starts a new one at the level you last started. The very first time, that is Easy.

**Getting around** [15.0, 15.1]

The title screen has PLAY, MENU, INFO, ABOUT and Buy me a coffee. Back on the title screen closes the game. Your puzzle is saved.

Buy me a coffee opens a page in your web browser where you can support the game if you want to. It is the only thing in the game that opens anything. The game itself never uses the internet.

MENU on the title screen opens the main menu. During a puzzle, tap the Pause button, then Menu. You also get there from Menu when you finish a puzzle. The main menu has Continue (when a puzzle is in progress), New puzzle, Lessons, Stats and Settings. Back on the main menu takes you to the title screen.

**The board** [2.1 to 2.3]

Some digits are there from the start. They are called givens. They look different from the digits you place, and they cannot be changed.

Tap any cell to select it. Its row, column and box light up. If the cell holds a digit, every other cell with that digit lights up too, so you can see where that digit already is.

**The candidate ring** [4]

Every empty cell shows the digits 1 to 9 around its inside edge: 1, 2, 3 and 4 across the top, 5 on the left, 6 on the right, and 7, 8 and 9 across the bottom. These are the candidates: the digits that might still go in that cell.

A digit is ruled out for a cell when the cell's row, column or box already holds it. Cross out the digits you rule out. A crossed digit stays readable, so you always see what you crossed. When you have crossed out all but one digit correctly, that last digit goes in the cell.

Example: a cell's row holds 9 and 3, its column holds 4 and 6, and its box holds 2, 3 and 4. Cross out 2, 3, 4, 6 and 9. That leaves 1, 5, 7 and 8 open.

The game never checks your crosses. You can cross out any digit, even all nine, and bring it back later.

If you would rather keep the candidates in your head, turn off Show candidates in Settings. The rings are hidden, and your crosses are kept for when you turn it back on.

**Place and Cross out** [3]

The pad has the digits 1 to 9 and a switch with two modes, Place and Cross out. The switch and the selected cell both show which mode is on.

Place: tap a digit to put it in the selected cell. Tap a different digit to replace it. While a cell holds a digit, its ring is hidden.

Cross out: tap a digit to cross it out in the selected cell's ring. Tap it again to bring it back. Cross out works only on empty cells.

Switching modes keeps your selected cell. You can place a digit even if you crossed it out.

With Show candidates off, the switch is hidden and every digit you tap is placed.

**Erase and Undo** [3, 4.3, 7]

Erase removes a digit you placed in the selected cell. Givens cannot be erased. When the digit goes, the ring comes back with your crosses exactly as you left them.

Erase does not clear crosses. To bring back a crossed digit, tap it again in Cross out mode.

Undo takes back your last change: a digit placed, replaced or erased, or a candidate crossed out or brought back. Tap it again to go further back, all the way to the start of the puzzle. Undo selects the cell it changed. Your undo history is kept when you close the game. Undo never gives back the cost of a hint.

**Auto Cross** [5]

Auto Cross is a setting, and it is off unless you turn it on. Crossing out by hand is how you learn to see the board.

While it is on, the game crosses out every candidate that a digit in the same row, column or box rules out. When that digit goes and nothing else rules the candidate out, Auto Cross brings it back. Its X looks different from yours. It never changes a digit you crossed out or brought back yourself. When you erase a digit, your own crosses come back exactly as you left them, and Auto Cross updates its crosses to match the board.

Auto Cross trusts every digit on the board, even a wrong one. A wrong digit makes it cross out candidates that should stay open.

Turning it off leaves its crosses where they are. Turning it on again updates them. Auto Cross does not change your score. It is always off in lessons.

**Mistakes** [6]

If the same digit is in a row, column or box more than once, every cell involved is marked. That is the only check while you play. A wrong digit that clashes with nothing is not marked. A hint will point it out, at the usual cost.

Marks cost no points. They go away as soon as the clash is fixed.

If the board is full but some digits clash, the puzzle is not finished. Fix the marked cells. A full board with no clash is always the right answer.

**Timer and pause** [8, 8.1]

The timer starts when the board appears. The time it takes to make the puzzle does not count. The timer runs only while you can see the board.

Tap the Pause button, or press Back, to open the pause menu. It hides the board and stops the timer. It has Resume, Settings and Menu.

When you leave the game, or another app takes over the screen, the game pauses too, and the pause menu is waiting when you come back. Time while the game is closed never counts.

If the game's window gets too small to play in, a message says so and the game pauses until the window is bigger again.

**Score** [9]

Each puzzle starts with points for its level. The score shows them while you play. It goes down only when you buy a hint, and never below zero. Time does not lower it.

Finish faster than the level's par time, a target time for the level, and you also get a time bonus. The bonus is the level's points times the part of the par time you had left, rounded down. At the par time or slower there is no bonus. Your final score is your points after hints plus the time bonus.

- Beginner: 100 points, a hint costs 20, par time 8:00
- Easy: 200 points, a hint costs 40, par time 12:00
- Medium: 400 points, a hint costs 80, par time 20:00
- Hard: 700 points, a hint costs 140, par time 30:00
- Expert: 1000 points, a hint costs 200, par time 45:00

A hint costs a fifth of the level's points, so five hints use them all up.

Example: you finish an Easy puzzle in 9:00 with one hint. Your points are 200 minus 40 for the hint, which is 160. The par time is 12:00, so you had 3:00 left, a quarter of it. The time bonus is a quarter of 200, which is 50. Your score is 160 plus 50, which is 210.

**Hints** [10]

Stuck? Tap the Hint button. A hint never fills anything in.

If a digit you placed is wrong, the hint points to it so you can erase it. Otherwise the hint shows the next step you can work out. It marks the cells involved, highlights any candidates to cross out, explains the step in a sentence or two and names the technique. A technique is a way of reasoning that finds a digit or rules candidates out. For the techniques the lessons teach, the hint also names the lesson.

The hint stays on screen until you close it, place, replace or erase a digit, or tap Undo. You can cross out candidates while it shows. If you close a hint and ask again, the new hint costs again.

With Show candidates off, a hint that says to cross out candidates shows just those candidates while it is on screen.

The Hint button is off while a hint is showing, once the puzzle is finished, and when your score is lower than a hint costs. That happens after five hints, when your score is 0.

**Levels** [11]

There are five levels: Beginner, Easy, Medium, Hard and Expert, all open from the start. To pick one, open the main menu and tap New puzzle. If a puzzle is in progress, the game asks first. The old puzzle then counts as started, not completed.

A level is set by the hardest technique the puzzle needs, not by how many digits it starts with.

- Beginner: last empty cell, a row, column or box with one empty cell left, and hidden single, a digit that fits in only one cell of a row, column or box
- Easy: also naked single, a cell where every digit but one is ruled out
- Medium, Hard and Expert: patterns across several cells. A hint names and explains each one when you need it.

**Finishing and stats** [12, 13]

A puzzle is finished the moment the board is full with no clash. The timer stops, and you see the level, your time, your points after hints, your time bonus, your score and the number of hints you used. Then choose Play again for another puzzle at the same level, or Menu.

Stats, on the main menu, show for each level: Started (puzzles whose board appeared, including ones you left unfinished), Completed, Best time, Average time (of completed puzzles) and Best score. They also show how many of the five lessons you have finished.

When a result beats your best at that level, the finish screen says New best time or New best score, or both. A tie is not a new best. The first puzzle you finish at a level shows neither, because there is nothing to beat yet.

**Lessons** [15.3, 15.4]

Five short lessons teach the basics: 1 How Sudoku works, 2 The ring and Cross Out, 3 Last empty cell, 4 Hidden single, 5 Naked single. Open them from Lessons on the main menu. The first time you tap PLAY, the game offers lesson 1.

In a lesson, a tap that is not the answer changes nothing and a short note tells you why, so you cannot fail. Lessons have no timer, score or hints, and Auto Cross is always off. Your puzzle in progress waits, with its timer stopped.

**Settings** [4.5, 5, 13.2, 14]

Settings opens from the main menu and from the pause menu.

- Sound: a click when you place a digit, or cross out a candidate or bring it back. On at first.
- Show candidates: shows the candidate ring in empty cells. Turn it off to hide every ring and the Place and Cross out switch, so every tap places a digit. Your crosses are kept, and Auto Cross keeps working, so turning it back on shows the rings as they are now. Lessons always show the ring. On at first.
- Auto Cross: see above. Off at first. You can change it while candidates are hidden.
- Skin: Light, the first choice, or Dark.
- Reset stats: clears the stats of every level after you confirm. Your lesson progress stays. This cannot be undone.

Decision: the Info screen also has a "Getting around" section, beyond the list in Bart's request.
- Reason: Lessons, Stats, Settings and New puzzle live on the main menu, not on the title screen, so a player needs to be told the three ways there: MENU on the title screen, the pause menu's Menu and the completion screen's Menu (15.0).
- Example: a player on the title screen who wants lesson 3 reads "MENU on the title screen opens the main menu", taps MENU, then taps Lessons.

### 15.6 About screen text

The About screen (ABOUT on the title screen) shows exactly this, in this order:

1. The title line: "Sudoku".
2. "Version {version}", where {version} is the app's version as the project settings give it at run time (ARCHITECTURE section 11).
3. "Designed and written by Bart Basi."
4. "Copyright 2026 Play, Inc. All rights reserved."
5. This paragraph: "Sudoku is free. It works offline, with no ads and no accounts, and it collects no data. Everything you do stays on this device."
6. "If you enjoy it and want to support the game, you can buy me a coffee." Then the Buy me a coffee button, which works exactly as the one on the title screen (15.0): it hands https://buymeacoffee.com/playinc to the phone's web browser.
7. "Questions, feedback and notices: bartbasi@gmail.com"
8. "Privacy policy: bartbasi.github.io/Sudoku/privacy"
9. "Made with the Godot Engine." This is the last line of the card.
10. The heading "Open source notices", with no lead sentence under it.
11. Under the heading, in this order:
   - The caption "Godot Engine", then the Godot Engine's license.
   - The heading "Third party components", then the notices for the third party code that ships inside the engine.
   - The heading "Licenses", then the license texts those components use.

   The screen reads all of these notices from the engine at run time; no notice text is copied into the game's own files or this document. They are shown word for word as the engine returns them, including any web addresses inside them. The only change allowed is joining the line breaks inside a paragraph so the text wraps to the screen.

- Items 1 to 9 are the game's own text (the card). The email address in item 7 and the privacy address in item 8 are plain text, not links: tapping them does nothing.
- Bart, 2026-10-17: the copyright is held by Play, Inc. The card credits Bart Basi as designer and writer, and the contact address is bartbasi@gmail.com. The repo is now public and the privacy page lives at bartbasi.github.io/Sudoku/privacy/, so the earlier rule that nothing on the screen contains "github" is retired.
- The only things on the screen that can be tapped are Back and the Buy me a coffee button. The open source notices are unchanged and cannot be tapped, web addresses inside them included.
- Only the Buy me a coffee button opens anything, and it opens the browser. The game itself never uses the network, and the screen works in airplane mode; the button then just opens the browser, which shows its own offline page.
- After the browser, coming back to the game shows the About screen. If Android closed the game in the meantime, coming back is an app start and shows the title screen (15.0).
- The text scrolls when it does not fit. Back returns to the title screen (15.0).

## 16. Acceptance tests

How to read them:
- Core: a unit test on the stated position, in tests/core or tests/puzzles. App: checked by hand in the running game.
- Unless a test says otherwise: settings at their defaults (sound on, Pop light skin, Auto Cross off, Show candidates on) and a new Beginner puzzle.
- E, F, G and H are empty cells the tester picks. Position B, X, Y and Z are defined in sections 4.4 and 5.3. AC-n and U-n are the examples in section 5.

### Board and input

**AT-01 New puzzle start state** (App)
- Steps: Start a new Beginner puzzle. Before selecting anything, tap 5 on the pad, then Erase, then Undo.
- Expected: every empty cell shows all nine candidates open. Givens look different from placed digits. No cell is selected and Place mode is on. The timer starts at 0:00 and runs. The HUD score is 100. Undo is disabled and Hint is enabled. The three taps do nothing.

**AT-02 Selection and peer highlight** (App)
- Steps: Tap E. Tap a given. Tap E twice. Tap outside the board.
- Expected: each tapped cell becomes the only selected cell, with its row, column and box highlighted. Tapping E twice keeps it selected. Tapping outside the board keeps the selection.

**AT-03 Same digit highlight** (App)
- Steps: Select a given holding d. Select E. Place a digit d2 in E.
- Expected: with the given selected, every other cell holding d shows the same digit state, and no ring slot does. With empty E selected, no cell shows it. After placing d2, every other cell holding d2 shows it.

**AT-04 Givens are locked** (App)
- Steps: Select a given. In Place mode tap 1 to 9, then Erase. Switch to Cross Out and tap 1 to 9.
- Expected: nothing happens each time. The given is unchanged, no click plays and Undo stays disabled.

**AT-05 Place** (App)
- Steps: Select E and tap 4.
- Expected: E shows 4 large in the center, in the placed style. Its ring is hidden. The click plays. Undo is enabled.

**AT-06 Replace** (App)
- Steps: E holds 4. Tap 7. Undo once.
- Expected: E shows 7 and the click plays. After one undo E shows 4.

**AT-07 Same digit again** (App)
- Steps: Select E. Tap 5, tap 5 again, then Undo once.
- Expected: the second tap does nothing and plays no click. After one undo E is empty, which shows the second tap made no undo step.

**AT-08 Erase** (App)
- Steps: E holds 5: tap Erase. Tap Erase again on the now empty E. Select a given and tap Erase. Repeat all of it in Cross Out mode.
- Expected: the first erase removes the 5 and shows E's ring as it was. Every later erase does nothing. Both modes behave the same. Erase never plays the click.

**AT-09 Cross and restore** (App)
- Steps: Cross Out mode. Select E. Tap 3. Tap 3 again. Undo twice.
- Expected: first tap: 3 shows the hand X and the digit stays visible; the click plays. Second tap: 3 is open again; the click plays. First undo: 3 crossed again. Second undo: 3 open.

**AT-10 Cross Out on a cell holding a digit** (App)
- Steps: E holds 6. Switch to Cross Out and tap 1 to 9. Erase the 6.
- Expected: the nine taps do nothing. After the erase, E's ring is exactly as it was before the 6 was placed.

**AT-11 Mode toggle** (App)
- Steps: With no undo steps yet, select E. Switch to Cross Out, then back to Place. Tap Undo.
- Expected: E stays selected the whole time and the board does not change. The toggle and the selected cell both show the current mode, and the modes can be told apart without color. Undo stays disabled.

**AT-12 Cross out all nine** (App, Core)
- Steps: Cross Out mode. Select E. Tap 1 to 9. Tap 4. Switch to Place, tap 2. Erase.
- Expected: after nine taps all nine show crossed by hand and stay visible, with no message or error. Tapping 4 restores only 4. Placing 2 works. After the erase the ring shows 1, 2, 3, 5, 6, 7, 8 and 9 crossed and 4 open.

**AT-13 A restore is remembered** (App, Core)
- Steps: Pick E and a digit d already in E's row. Cross d in E, then restore it. Turn Auto Cross on.
- Expected: after the restore, d looks exactly like a never crossed candidate. After Auto Cross is turned on, d in E stays open (restored by hand), while E's other ruled out candidates are crossed by Auto Cross.

**AT-14 Bart's example** (Core, App)
- Steps (Core): set up Position B. Ask which of X's candidates are ruled out. Cross 2, 3, 4, 6 and 9 in X. Place 8 in X, then erase it. Then, on a fresh Position B, turn Auto Cross on.
- Steps (App): open the candidate ring lesson (lesson 2 in the current outline) and do its Bart's example step in Cross Out mode.
- Expected: ruled out is exactly 2, 3, 4, 6 and 9. After crossing, those five are crossed by hand and 1, 5, 7 and 8 are open, with all nine visible. After the place and erase the ring is the same. With Auto Cross on, exactly 2, 3, 4, 6 and 9 in X are crossed by Auto Cross and 1, 5, 7 and 8 are open. In the lesson, crossing 2, 3, 4, 6 and 9 gives that ring and the lesson accepts it.

**AT-15 Erase brings the ring back unchanged** (App, Core)
- Steps: In E cross 1, 4 and 9, then restore 4. Place 6 in E. Place 3 in F, a peer of E where 3 clashes with nothing. Erase E's 6.
- Expected: E's ring shows 1 and 9 crossed by hand and every other digit open, 3 and 4 included, exactly as before the 6 was placed.

**AT-16 Place over a crossed candidate** (App)
- Steps: In E cross 7. Switch to Place and tap 7. Erase.
- Expected: E shows 7. After the erase the ring shows 7 crossed by hand.

**AT-17 Click sound** (App)
- Steps: Place, replace, cross, restore, erase, undo, switch mode, select a cell, and tap a digit on a given. Then turn sound off in Settings and place a digit.
- Expected: the click plays for place, replace, cross and restore only. After sound is off it never plays.

### Undo

**AT-18 Undo across mode switches** (App, Core)
- Steps: Place mode: place 5 in E. Switch to Cross Out: cross 2 in F. Switch to Place: place 7 in G. Undo three times.
- Expected: first undo: G empty and selected, mode Place. Second: F's 2 open, F selected, mode Place. Third: E empty and selected. Undo is now disabled. The mode never changed during the undos.

**AT-19 Undo of replace, erase, cross and restore** (Core, App)
- Steps: In E place 4, replace it with 7, erase. In F cross 3, restore 3. Undo five times.
- Expected, one line per undo: F's 3 crossed by hand; F's 3 open; E shows 7; E shows 4; E empty.

**AT-20 What is not an undo step** (App)
- Steps: Place 5 in E. Then select other cells, switch mode twice, buy a hint and close it, pause and resume, and tap a digit on a given. Undo once.
- Expected: the one undo removes the 5 from E. The score stays reduced by the hint cost.

### Auto Cross

**AT-21 Off by default** (App)
- Steps: Fresh install. Open Settings. Start a puzzle and play a few digits.
- Expected: Auto Cross is off. No candidate is crossed except by the player's own taps.

**AT-22 Turning it on mid-puzzle next to hand marks** (Core, App)
- Steps (Core): run AC-1.
- Steps (App): Pick E and note the set R of digits in its row, column and box. In E cross one digit of R by hand, cross one digit not in R by hand, and cross and restore another digit of R. Turn Auto Cross on from the pause menu's Settings and resume.
- Expected (Core): X as AC-1 states. Expected (App): in E the two hand crosses are unchanged and keep the hand look. The restored digit stays open. Every other digit of R is crossed with the Auto Cross look. Every other digit is open. Other empty cells have their ruled out candidates crossed by Auto Cross.

**AT-23 Placing with Auto Cross on** (Core, App)
- Steps (Core): run AC-2. Steps (App): Auto Cross on. Pick E and a digit d that is open in some of E's peers. Place d in E. Undo once.
- Expected: every open d in E's row, column and box is crossed by Auto Cross. Hand marks do not change. One undo removes d and reopens all of those.

**AT-24 Replacing with Auto Cross on** (Core)
- Steps: run AC-1, AC-2 and AC-3.
- Expected: as AC-3 states, done as one undo step.

**AT-25 Erasing with Auto Cross on** (Core, App)
- Steps (Core): run AC-1 to AC-4.
- Steps (App): Auto Cross on. Place d in E. Place d in F, which shares no group with E. Pick G, empty, a peer of both E and F. Pick H, empty, a peer of E but not of F, whose d was open before E got its d. Erase E's d.
- Expected (Core): as AC-4. Expected (App): G's d stays crossed by Auto Cross, because F still rules it out. H's d is open again.

**AT-26 A hand restore is never re-crossed** (Core, App)
- Steps (Core): run AC-1 to AC-5.
- Steps (App): Auto Cross on. In E, tap a candidate d that is crossed by Auto Cross. Then place d in an empty peer of E where it clashes with nothing.
- Expected: E's d shows open after the tap and stays open after the placement.

**AT-27 A hand cross outlives its digit** (Core)
- Steps: run AC-1 to AC-6.
- Expected: as AC-6. X's 5 stays crossed by hand after the 5 in r9c5 is erased.

**AT-28 Turning it off and on again** (Core, App)
- Steps (Core): run AC-1 to AC-7.
- Steps (App): Auto Cross on. Place d in E. Note G, a peer of E whose d was just crossed by Auto Cross and that no other d rules out. Turn Auto Cross off. Erase E's d. Turn Auto Cross on.
- Expected: turning it off changes nothing on the board, and the Auto Cross Xs keep their look. After the erase, G's d stays crossed by Auto Cross. After turning it on again, G's d is open. Hand marks never change.

**AT-29 A ring hidden under a digit** (Core)
- Steps: run AC-8, both with Auto Cross on and with it off.
- Expected: as AC-8 states for each case.

**AT-30 Auto Cross and undo** (Core)
- Steps: run U-1 to U-5.
- Expected: as each example states.

**AT-31 Auto Cross trusts wrong digits** (Core)
- Steps: take a puzzle with its solution. Auto Cross on. Place in E a digit d that is wrong but clashes with nothing. Then erase it.
- Expected: every open d in E's peers is crossed by Auto Cross, including in the cell whose answer is d. After the erase they reopen, except where another d still rules them out. The solution is never read.

**AT-32 Auto Cross X and hand X look different** (App)
- Steps: on one board, show candidates crossed by hand, candidates crossed by Auto Cross, and one cell with all nine crossed by hand. Do it in Pop light and in Pop dark, with the board at its size on a 360 dp wide screen (as AT-66). Run the contrast script.
- Expected: the two Xs can be told apart without color. Both pass 3:1. Every digit crossed by hand is drawn on top of its X with a thin outline and reads clearly, in the cell with all nine crossed too. Every digit crossed by Auto Cross stays visible. Restored by hand looks exactly like open.

**AT-33 Auto Cross does not change the score** (Core)
- Steps: compute the final score for the same level, time and hints with Auto Cross on, off, and switched during play.
- Expected: the three scores are equal and match section 9.2.

### Mistakes

**AT-34 Conflicts shown and cleared** (App, Core)
- Steps: Pick a given d. Place d in an empty cell E in the given's row but outside its box. Place d in an empty cell F in the given's box but outside its row. Erase E's d.
- Expected: after the first placement the given and E show the conflict state. After the second, F shows it too. After the erase, E clears and the given and F still show it. Score unchanged throughout.

**AT-35 No check against the solution** (Core)
- Steps: take a puzzle with its solution. Place a wrong digit that clashes with nothing.
- Expected: no conflict state and no other sign on the board. Score unchanged.

**AT-36 Full board with a clash** (Core, App)
- Steps (Core): fill every empty cell with its solution digit except the last one in reading order, which gets a wrong digit. Then replace it with the right digit.
- Steps (App): solve a Beginner puzzle but put a wrong digit in the last empty cell. Then replace it with the right one.
- Expected: with the wrong digit, the clash shows, the puzzle does not complete, the full board message appears and the timer keeps running. The message closes at the next action. After the fix the puzzle completes.

### Timer

**AT-37 Timer runs and pauses** (App)
- Steps: start a Hard puzzle and note how long generation takes. Play 10 s. Open the pause menu for 30 s, then Settings from it, then resume. Send the app to the background for 30 s and come back. Go to the main menu for 30 s and tap Continue.
- Expected: the timer starts at 0:00 when the board appears, not before. It stops in the pause menu, in Settings, in the background and on the main menu. On return from the background the pause menu is showing and the timer waits for Resume. In the end it shows only the time spent on the board, within one second.

**AT-38 Pause menu and Back** (App)
- Steps: during a puzzle press Android Back. Press Back again.
- Expected: the first Back opens the pause menu and the board is hidden. The second resumes play.

### Score

**AT-39 Score formula** (Core)
- Steps: compute the five examples of section 9.3. Also try t = P, t greater than P, and five hints.
- Expected: exactly the final scores in the table. T is 0 when t is P or more. S is never below 0.

**AT-40 HUD score** (App)
- Steps: start a Medium puzzle. Wait one minute. Buy a hint.
- Expected: the HUD shows 400, still 400 after the minute, and 320 after the hint.

### Hints

**AT-41 Hint points at a wrong digit** (App, Core)
- Steps (App): new Beginner puzzle. In an empty cell, place a digit that clashes with a given in its row, so it is surely wrong. Tap Hint.
- Steps (Core): place two wrong digits and ask for a hint.
- Expected: the placed cell is the hint target, the text is "This {d} is not right. Erase it and look again.", the score drops from 100 to 80 and the board does not change. In the core test the hint picks the wrong digit that comes first in reading order.

**AT-42 Hint shows the next step** (App)
- Steps: new Beginner puzzle, nothing placed. Tap Hint.
- Expected: a Last empty cell or Hidden single step, with its target and reason cells marked, one or two sentences, the technique name and the lesson title (Lesson: Last empty cell or Lesson: Hidden single). The score is 80. The board, the selection and the mode do not change, and Undo stays disabled.

**AT-43 Hint skips steps already done** (Core)
- Steps: take a Medium position where the first step the solver finds is an elimination. Ask for a hint and note its targets. Cross all of them by hand. Ask again. Then cross the solution digit of some empty cell by hand and ask once more.
- Expected: the second hint is a different step. The wrong cross does not change what the third hint finds.

**AT-44 Hint stays and closes** (App)
- Steps: buy a hint. Select other cells, cross a candidate and restore it. Then place a digit. Repeat with erase, replace, undo and the close button in place of the placement. Then buy a hint, close it and tap Hint again.
- Expected: the hint stays through selecting, crossing and restoring. Each of place, erase, replace, undo and close closes it. While it shows, Hint is disabled. Asking again after closing costs again.

**AT-45 Hint at zero score** (App)
- Steps: new Beginner puzzle. Buy five hints, closing each one. Tap Hint again. Then finish the puzzle.
- Expected: the score goes 100, 80, 60, 40, 20, 0. After the fifth hint the Hint button looks disabled, and tapping it does nothing: no charge, no hint, no sound. The score stays 0, never below. The puzzle can still be completed, and the final score equals the time bonus alone.

**AT-46 Hint cost per level** (Core)
- Steps: check the hint cost and affordability for each level.
- Expected: cost 20, 40, 80, 140 and 200 for Beginner to Expert. A hint can be bought exactly when the score is at least the cost.

**AT-47 Hints are repeatable** (Core)
- Steps: ask for a hint twice on the same position with the same ring.
- Expected: the same technique, cells and text both times.

**AT-48 A hint on screen survives a restart** (App)
- Steps: buy a hint. Kill the app. Reopen and tap PLAY on the title screen.
- Expected: the same hint is on screen and the score was charged once.

**AT-69 Hint highlights the candidates to cross** (Core, App)
- Steps (Core): take the Medium position from AT-43, where the first step is an elimination. Cross by hand one of the candidates that step removes. Ask for a hint. Then ask for a hint on a position whose next step is a placement, and on one with a wrong digit.
- Expected (Core): the elimination hint lists every candidate the step crosses in Hint.eliminations, and the board draw state's hint_crosses equals that list. Its targets are only the cells where at least one of those candidates still shows open. The placement hint and the wrong digit hint have empty eliminations.
- Steps (App): start a Medium puzzle with Auto Cross on. Place digits by hand until a hint names Pointing, Claiming or Naked pair (place the digit of any placement hint and close it). Note the highlighted candidates. Cross one of them, then restore it. Close the hint.
- Expected (App): in each target cell, exactly the open candidates the hint text says to cross are highlighted, and nothing else on the ring is. Crossing one removes its highlight and keeps the hint; restoring it brings the highlight back. Closing the hint removes every highlight. A placement hint highlights no candidate.

### Levels

**AT-49 Grading** (Core)
- Steps: generate a sample of puzzles per level from fixed seeds. Generate one seed twice.
- Expected: each puzzle has exactly one solution. The technique solver finishes it using only techniques the level allows and at least one it needs. The same seed gives the same puzzle and ID.

**AT-50 Techniques** (Core)
- Steps: for each of the 13 techniques in 11.3, build a board containing its example pattern. Also build boards without each pattern.
- Expected: the solver reports the technique with the stated conclusion where the pattern is, and never reports it where it is not.

**AT-68 Givens floor** (Core)
- Steps: generate 200 Beginner and 200 Easy puzzles from seeds 1 to 200. Count the givens in each.
- Expected: every Beginner puzzle has at least 36 givens and every Easy puzzle at least 32. Each one still passes AT-49: exactly one solution, and it grades at its level (a Beginner puzzle uses at least one hidden single, an Easy puzzle at least one naked single).

### Completion and stats

**AT-51 Completion** (App)
- Steps: complete a Beginner puzzle. Then tap Play again.
- Expected: at the last placement the timer stops and the board locks (no input, Undo and Hint disabled). The completion screen shows the level, the time, the score with points after hints, time bonus and total, and the hints used. The main menu shows no Continue. Play again starts a new Beginner puzzle with no dialog.

**AT-52 Stats when a puzzle starts** (App)
- Steps: note Easy's Started. Start an Easy puzzle. Check Stats. Leave, tap Continue, check again. Kill the app, reopen, tap PLAY, check again.
- Expected: Started is 1 higher right after the start, and does not change on any resume.

**AT-53 Stats on completion** (Core, App)
- Steps (Core): record two Easy completions, 300 s with score 276 and 401 s with score 208.
- Steps (App): complete a puzzle and check its level's stats.
- Expected (Core): completed 2, best time 5:00, average time 5:51, best score 276. Expected (App): Completed +1, and best time, average time and best score match the result.

**AT-54 Abandon** (App)
- Steps: start a Medium puzzle and play a little. New puzzle, choose Easy, tap Start new.
- Expected: Medium Started stays 1 higher than before, and Medium Completed, times and score are unchanged. Easy Started goes up by 1. The Medium puzzle and its undo history are gone.

**AT-55 Reset Stats** (App)
- Steps: have stats on several levels, one finished lesson and a Medium puzzle in progress. Settings, Reset Stats, Cancel. Then Reset Stats, Reset. Then complete the Medium puzzle.
- Expected: Cancel changes nothing. After Reset every level shows 0 started, 0 completed and "-" for times and score, except Medium Started, which is 1. Lessons completed is unchanged. The puzzle in progress continues. After completing it, Medium shows 1 started and 1 completed.

**AT-56 Lessons completed** (App)
- Steps: finish a lesson. Finish it again. Leave another lesson halfway.
- Expected: Lessons completed goes up by 1 the first time only. Leaving halfway changes nothing.

### Persistence

**AT-57 Resume after the app is killed** (App)
- Steps: Auto Cross on. Mid puzzle, have placed digits, hand crosses, hand restores, Auto Cross crosses, one hint bought and closed, Cross Out mode on, a cell selected, about 3 minutes on the timer, and several undo steps. Send the app to the background and swipe it away (or force-stop it). Reopen and tap PLAY on the title screen. Then undo step by step. Repeat once with a force-stop right after an action, without going to the background first.
- Expected: every digit, every candidate with its exact state and look, the score, the mode and the selected cell are as they were. The timer is within one second of its value when the app went to the background. Undo works back to the start of the puzzle. After the force-stop variant, the last action is there.

**AT-58 Settings persist** (App)
- Steps: fresh install. Open Settings and look at the skin picker. Turn sound off, pick Pop dark, turn Auto Cross on. Kill the app and reopen.
- Expected: the skin picker offers exactly two skins, Pop light and Pop dark, with Pop light selected on the fresh install. After reopening, all three settings are as set and the game shows Pop dark.

**AT-59 Stats and lesson progress persist** (App)
- Steps: after AT-53 and AT-56, kill the app and reopen.
- Expected: stats and lessons completed are unchanged.

**AT-60 Damaged save** (Core, App)
- Steps: replace the saved puzzle with unreadable data. Then with readable data holding impossible values (a digit 12, a cell index 99, a negative timer). Start the game each time.
- Expected: the game starts without crashing on the title screen, and there is no puzzle in progress: PLAY starts a new puzzle at the last level started instead of resuming one. Settings, stats and lesson progress load normally.

### Flow and lessons

**AT-61 New puzzle while one is in progress** (App)
- Steps: with a puzzle in progress, tap New puzzle and choose Hard. Tap Keep playing. Do it again and tap Start new. Then, with no puzzle in progress, tap New puzzle and choose Easy.
- Expected: level select shows five levels, all open. The dialog names both levels. Keep playing returns to the old puzzle unchanged. Start new abandons it as AT-54 describes and starts a Hard puzzle. With nothing in progress, Easy starts with no dialog.

**AT-62 First launch** (App)
- Steps: fresh install. Launch and tap PLAY. Kill the app before answering. Launch again, tap PLAY and tap Skip. Kill and launch again, and tap PLAY. Tap Pause, then Menu, and open the Lessons screen. Then fresh install again, launch, tap PLAY and tap Start lesson. Leave the lesson.
- Expected: each launch opens the title screen, never the offer. The offer shows on the first PLAY and again on the first PLAY after the kill. Skip goes straight into a new Easy puzzle. After the next launch, PLAY resumes that puzzle and the offer never shows again. Lesson 1 is in the Lessons screen. Start lesson opens lesson 1, and leaving it shows the main menu. The full title screen flow is AT-72 to AT-76.

**AT-63 Lesson wrong answers** (App)
- Steps: in a lesson step, do each of these wrong taps in turn: select a different cell; with the taught cell selected, tap a wrong digit; in a Cross Out step, cross a candidate that should stay open; tap the mode toggle when switching is not part of the answer. Then do the right taps.
- Expected: each wrong tap changes nothing: the board, the ring, the selection and the mode stay as they were. The lesson's short explanation shows and the step stays. Selecting another cell leaves the taught cell selected. There is no way to fail. The right taps move the lesson on, and finishing the last step's answer counts the lesson as finished.
- Steps, part 2: complete a step's answer, and before tapping Next, tap a different cell, a digit, the mode toggle, Erase and Undo.
- Expected, part 2: the praise line and Next stay. Nothing changes on the board, the ring, the selection or the mode, and no explanation shows. Tapping Next moves on.

**AT-64 Lessons and the puzzle in progress** (App)
- Steps: Auto Cross on and a puzzle in progress at 2:00. Open a lesson that has empty cells next to digits and spend a minute in it. Leave and tap Continue.
- Expected: no candidate in the lesson is crossed by Auto Cross. The lesson shows no timer, score or Hint button. The puzzle in progress is unchanged and its timer still shows 2:00.

**AT-65 Rotation lock** (App, on a phone)
- Steps: with auto-rotate on, turn the phone to landscape on the title screen, on the main menu, during a puzzle, in a lesson and with a dialog open.
- Expected: the screen stays portrait. Nothing moves or changes, and the timer is unaffected.

**AT-66 Tiny and huge screens** (App)
- Steps: run in portrait at three sizes, each with safe area insets for a notch and a gesture bar: 320 by 568 dp; 360 dp wide on a screen tall enough that the width sets the board's size (for example 360 by 800 dp); and 1024 by 1366 dp. At each size play a few moves and open every screen. At 360 dp wide, also run the contrast script and measure the candidate digits.
- Expected: at all three sizes the whole board, the HUD and the pad show without scrolling. Cells are square. Nothing overlaps, is cut off, or sits under the notch or gesture bar. Input works. 320 by 568 dp is the smallest screen the game must fit and work on; candidate size and contrast are not judged there. Readability, meaning candidate size and contrast, is judged at 360 dp wide: the contrast script passes, and the candidate digits are no smaller than the minimum in docs/DESIGN_SYSTEM.md.

### Completion labels

**AT-67 New best labels** (Core, App)
- Steps (Core): start with no Easy stats. Record the six Easy completions of the table in 12.1, in order, and note the labels each one gets. Then Reset Stats and record one more Easy completion: 6:41 (401 s), 2 hints, score 208.
- Steps (App): start with no Beginner completions (fresh install, or after Reset Stats). Complete a Beginner puzzle using one hint. Complete a second Beginner puzzle faster than the first, using no hints. Complete a third Beginner puzzle more slowly than the second, using one hint.
- Expected (Core): the labels are, in order: none; none; New best score only; New best time only; both; none. Before the reset the Easy row shows best time 4:00 and best score 333. The completion after the reset gets no label.
- Expected (App): the first completion screen shows no label. The second shows both "New best time" and "New best score", because it is faster and its score is at least 20 higher (no hint cost, and a time bonus at least as large). The third shows no label. The Beginner stats then show the second puzzle's time and score as the bests.

### Window shapes

These run on a Galaxy Z Fold5, or in the editor with the window set to each size in dp and the stated insets. "Status bar" is a 32 dp inset at the top, "gesture bar" a 24 dp inset at the bottom, "taskbar" a 48 dp inset at the bottom in place of the gesture bar. Measure sizes on a screenshot, converting pixels to dp by the screen density (2.625 on the Fold5).

**AT-70 Window shapes** (App)
- Steps: run the game in each window below. In each, start or continue a Medium puzzle, select a cell, place a digit, cross a candidate, buy a hint and leave it on screen, then open the pause menu, Settings, the main menu, the title screen, the Info screen, the About screen, level select, stats, the lessons list, a lesson, and the "Start a new puzzle?" dialog. Complete a Beginner puzzle in at least one stacked window and one side by side window to see the completion screen. Then, mid puzzle with a hint on screen, change the window from the inner full screen to the inner top half and back.

| Window (dp) | Insets | Expected arrangement |
| --- | --- | --- |
| 320 by 568 | status bar, gesture bar | Stacked |
| Cover, full, 344 by 882 | status bar, gesture bar | Stacked |
| Cover, top two thirds, 344 by 588 | status bar | Stacked |
| Inner, full, 690 by 829 | status bar, gesture bar | Stacked |
| Inner, full, 690 by 829 | status bar, taskbar | Stacked |
| Inner, left or right half, 345 by 829 | status bar, gesture bar | Stacked |
| Inner, two thirds wide, 460 by 829 | status bar, gesture bar | Stacked |
| Inner, top half, 690 by 400 | status bar | Side by side |
| Inner, bottom half, 690 by 400 | gesture bar | Side by side |
| Inner, top two thirds, 690 by 553 | status bar | Side by side |
| 700 by 420 | none | Side by side |

- Expected: each window shows the arrangement in the table, and the board sizes match the table in docs/DESIGN_SYSTEM.md section 4.11 within 1 dp. Stacked: header row and band, board, pad, top to bottom. Side by side: the board at the left, and at the right the header row, the band with the level sticker, and the pad; the header row reads Pause, time, score, Hint from the board outward, so Hint is at the far end and never next to the board. In every window and on every screen: the board's cells are square; every control other than a cell has a touch area of at least 48 by 48 dp; nothing overlaps, is cut off, or sits under an inset; the hint panel never covers a cell; every input works as in a stacked window. Changing the window shape mid puzzle keeps every digit, ring mark, the selection, the mode, the hint on screen with its highlights, the score and the undo history; the timer is not reset, and it stops only if the game lost focus, in which case the pause menu is showing.

**AT-71 Too small window** (App)
- Steps, part 1: on the inner full screen, start a Medium puzzle, place a digit, cross a candidate, buy a hint and leave it on screen, and play until the timer shows about 1:00. Change the window to the cover screen's top half (344 by 430 dp, status bar). Wait 30 s. Tap the middle of the message, tap where the pad was, and press Back. Grow the window back to the inner full screen. Note the timer, then tap Resume and undo twice.
- Expected, part 1: the moment the window shrinks, a full screen message reads exactly "This window is too small. Make it bigger to play." and the timer stops. The taps and Back change nothing, play no sound and do not resume. After the window grows, the message is gone and the pause menu is showing, with the same time as when the window shrank. After Resume the board shows the same digit, the same crossed candidate and the same hint, the timer runs on from that time, the score was charged for one hint only, and the two undos reverse the cross and then the placement.
- Steps, part 2: repeat the shrink and grow with each other too small window: the cover screen's bottom half (344 by 430 dp, gesture bar), the inner screen one third wide (230 by 829 dp, status bar and gesture bar) and the inner screen's bottom third (690 by 276 dp, gesture bar). Do it once on the main menu, once in a lesson in the middle of a step, once with the "Start a new puzzle?" dialog open, and once while a Hard puzzle is being made.
- Expected, part 2: each of those windows shows the message, and every tap on it does nothing. When the window grows, the main menu, the lesson on the same step, and the dialog with nothing chosen are back exactly as left. The Hard puzzle opens behind the pause menu with the timer at 0:00, and the timer starts only after Resume.

### Title screen

**AT-72 Title screen on every start** (App)
- Steps: fresh install and launch. Kill the app and launch again. Start a puzzle, play a little, kill the app and launch again. Then, mid puzzle, send the app to the background without killing it and come back. Last, on the title screen, press Android Back.
- Expected: every launch opens the title screen: the wordmark, the hero, then PLAY, MENU, INFO, ABOUT and Buy me a coffee, top to bottom, with Buy me a coffee less prominent than the other four, no Continue button and no lesson offer. Coming back from the background without a kill shows the puzzle with the pause menu open, not the title screen. Back on the title screen closes the app, and on the next launch the puzzle is still in progress (PLAY resumes it).

**AT-73 The first PLAY offers lesson 1** (App)
- Steps: fresh install, launch, tap PLAY. Press Android Back. Tap PLAY again. Kill the app, launch, tap PLAY. Tap Skip. Note the level, score and timer. Kill the app, launch, tap PLAY. Then fresh install again, launch, tap PLAY, tap Start lesson, leave the lesson, press Back on the main menu, and tap PLAY.
- Expected: the offer reads "New to Sudoku? Lesson 1 shows you how to play." with Start lesson and Skip. Back returns to the title screen without answering, and the offer shows on the next PLAY and again after the kill. Skip goes straight into a new Easy puzzle (score 200, timer from 0:00), with no main menu in between, and Easy Started goes up by 1. After the next launch PLAY resumes that puzzle and the offer never shows again. On the second install, Start lesson opens lesson 1, leaving it shows the main menu, Back shows the title screen, and PLAY starts a new Easy puzzle with no offer.

**AT-74 PLAY resumes the puzzle in progress** (App)
- Steps: in a puzzle, select a cell, switch to Cross Out, and play until the timer shows 2:00. Note Started for its level. Tap Pause, then Menu, then press Back. On the title screen wait 30 s, open INFO for 30 s, go back, open ABOUT, go back. Tap PLAY. Then tap Pause, Menu, Back again, kill the app, launch it and tap PLAY.
- Expected: both times PLAY opens the same puzzle with no dialog and no making a puzzle card: every digit and ring mark as left, the same cell selected, Cross Out on, and the timer running on from the time it showed when the player tapped Pause (2:00 the first time), never counting the time on the title, Info or About screens. Started is unchanged.

**AT-75 PLAY starts a new puzzle at the last level started** (Core, App)
- Steps (Core): save settings with the last level Hard and load them. Then load settings where the last level is missing, is 7, is -1 and is the text "Hard". Then Reset Stats with the last level Medium.
- Expected (Core): Hard loads as Hard. Each of the four damaged values loads as Easy, and the other settings load normally. Reset Stats leaves Medium.
- Steps (App): with the lesson offer answered and a puzzle in progress, tap Pause, Menu, New puzzle, choose Beginner and tap Start new. Complete the Beginner puzzle. Kill the app on the completion screen. Launch, note Beginner Started, and tap PLAY twice quickly. Then tap Pause, Menu, New puzzle, choose Medium and tap Start new. Tap Pause, Menu, Back, and PLAY.
- Expected (App): after the relaunch PLAY starts one new Beginner puzzle (score 100, timer from 0:00), the making a puzzle card shows if making it takes a moment, and Beginner Started goes up by exactly 1, so the second tap started nothing. The last PLAY resumes the Medium puzzle.

**AT-76 Main menu and Back** (App)
- Steps: with a puzzle in progress at a time T, tap Pause, then Menu. Open Stats and press Back. Press Back on the main menu. On the title screen tap MENU, note the level's Started on Stats, go back, wait 30 s on the main menu and press Back. Tap PLAY and complete the puzzle. On the completion screen tap Menu, then press Back. Tap MENU.
- Expected: the main menu shows Continue, New puzzle, Lessons, Stats and Settings, as before, whether reached by Pause and Menu or by MENU. Back on Stats returns to the main menu. Back on the main menu opens the title screen every time and never closes the app. MENU starts no puzzle and leaves Started unchanged. PLAY resumes the puzzle at T, not counting the time on the main menu. After the completion, the main menu reached by MENU has no Continue.
- Steps, part 2: fresh install, launch, tap MENU, press Back, tap PLAY.
- Expected, part 2: MENU opens the main menu with no lesson offer and no Continue. The offer shows on the PLAY that follows.

**AT-77 Info screen** (App)
- Steps: on the title screen tap INFO. Read the whole screen, scrolling to the end, at 320 by 568 dp and at 360 by 800 dp. Press Back. Then check the 15.5 text against the GDD: the levels' points, hint costs and par times against 9.1; the Easy example with the formula in 9.2; the skin names against the Settings skin picker; the lesson titles against the Lessons screen.
- Expected: the Info screen opens over the title screen and shows the text of 15.5 word for word, with its fifteen headings in order, from How to play to Settings, and none of the bracketed section numbers. Every line can be reached by scrolling and nothing is cut off. Back returns to the title screen. The numbers match 9.1 exactly, the example gives 160 plus 50, which is 210, as in 9.3, and the skin names and lesson titles match the screens. The text has no em dash and no double hyphen.

**AT-78 About screen** (Core, App)
- Steps (App): turn on airplane mode. On the title screen tap ABOUT. Read the whole screen, scrolling to the end. Tap the email address, the privacy address, the card's other lines, and every web address in the notices. Press Back. (The Buy me a coffee button is AT-86.)
- Steps (Core): build the About screen's text and compare it with what the engine returns at run time and with the project's version setting.
- Expected: in order: "Sudoku"; "Version" followed by the version in the project settings; "Designed and written by Bart Basi."; "Copyright 2026 Play, Inc. All rights reserved."; the paragraph of 15.6 word for word; "If you enjoy it and want to support the game, you can buy me a coffee." followed by the Buy me a coffee button; "Questions, feedback and notices: bartbasi@gmail.com"; "Privacy policy: bartbasi.github.io/Sudoku/privacy"; "Made with the Godot Engine." as the last line of the card; the heading "Open source notices" with no sentence under it; the caption "Godot Engine" and the engine's license; the heading "Third party components" and the component notices; the heading "Licenses" and the license texts. The notices are not empty and list the third party components the engine reports. The engine's license, the component notices and the license texts match what the engine returns word for word, including their own web addresses; the only difference allowed is that line breaks inside a paragraph are joined. The card (from "Sudoku" to "Made with the Godot Engine.") contains no "http" and no "www", and the coffee address is not shown as text. The email and privacy addresses are plain text: tapping them, any other line of the card, or anywhere in the notices, including on every web address there, opens nothing and does nothing. The only things that react to a tap are Back and the Buy me a coffee button. The screen works in airplane mode. Back returns to the title screen. A search of the repo for the first line of the engine's license text, as the screen shows it, finds nothing.

**AT-86 Buy me a coffee** (App)
- Steps, part 1: fresh install. Tap MENU, New puzzle, Easy, so the lesson offer is not yet answered. Select a cell, switch to Cross Out and play until the timer shows 2:00. Go to the title screen (Pause, Menu, Back). Note Easy Started. With the phone online and `adb logcat` running, tap Buy me a coffee. Read the browser's address bar and the intent line in the log. Switch back to Sudoku with the recent apps button. Then tap ABOUT, scroll to the button, tap it, and switch back to Sudoku the same way. Press Back, then tap PLAY.
- Expected, part 1: each tap opens the phone's web browser on exactly https://buymeacoffee.com/playinc, with nothing added to the address, and the log shows one view intent with that address per tap. Nothing else happens in the game. Switching back shows the title screen the first time and the About screen the second time, as left, with no dialog and no lesson offer. PLAY then shows the lesson 1 offer, so the coffee taps did not answer it. After Skip, the Easy puzzle is as left: every digit and mark, the same cell selected, Cross Out on, the timer running on from 2:00 and never counting the time in the browser. Easy Started is unchanged, and Settings and Stats are as before.
- Steps, part 2: turn on airplane mode. Tap Buy me a coffee on the title screen, switch back, then tap it on the About screen and switch back.
- Expected, part 2: each tap opens the browser, which shows its own offline page. The game shows no message and no error, and switching back shows the screen as left.
- Steps, part 3: with no puzzle in progress, on the title screen tap PLAY and at once tap Buy me a coffee, several times, while the making a puzzle card shows.
- Expected, part 3: the browser does not open. The new puzzle starts as AT-75 describes, and its level's Started goes up by exactly 1.

### Show candidates

**AT-79 The Settings row and its default** (App, Core)
- Steps (App): fresh install. Open Settings from the main menu. Read the rows top to bottom. Turn Show candidates off, kill the app, launch it and open Settings again. Turn it on, kill, launch, open Settings.
- Expected (App): the rows are Sound, Show candidates, Auto Cross, Skin, Reset stats. The row's name is "Show candidates", its switch is on, and the line under it reads exactly "Shows the candidate ring in empty cells. Off, every tap places a digit. Your marks stay." After each relaunch the switch is as it was set. No other setting changed.
- Steps (Core): save settings with Show candidates off and load them. Then load settings where Show candidates is missing, is the text "false", and is an empty list.
- Expected (Core): off loads as off. Each damaged value loads as on, and the other settings load normally.

**AT-80 What hiding shows and hides** (App)
- Steps: Auto Cross on. In a Beginner puzzle, cross two candidates by hand in E, restore one candidate in F that Auto Cross had crossed, place a digit d in G, and place a digit in H that clashes with a given, so a conflict shows. Select G. Take a screenshot. Open the pause menu, Settings, turn Show candidates off, go back and Resume. Take a second screenshot. Tap a digit in a fresh empty cell, then tap Erase.
- Expected: in the second screenshot no empty cell shows any small digit or any X. The givens, the placed digits, G's selection, its row, column and box, the same digit highlight on every other d, and the conflict marks look exactly as in the first screenshot. The mode toggle is gone and the pad's other controls still work. Every control left has a touch area of at least 48 by 48 dp and nothing overlaps. The digit tap places the digit with the click, and Erase removes it. The score and the timer are not affected.

**AT-81 Turning it off in Cross Out** (App, Core)
- Steps (App): select E, switch to Cross Out and cross 3 in E. Open the pause menu, Settings, turn Show candidates off, go back and Resume. Tap 6. Tap Undo twice. Turn Show candidates on. Then switch to Cross Out again, open the main menu (Pause, Menu), open Settings there, turn Show candidates off, go back and tap Continue. Kill the app, launch it and tap PLAY.
- Expected (App): after the first Resume, E is still selected with the Place look and the toggle is hidden. Tapping 6 places 6 in E. The first undo empties E, and the second undo reverses the cross of 3 (E stays selected, nothing else shows), so the mode switch made no undo step. After turning it on, the toggle shows Place and E's ring is all open. After Continue the puzzle is in Place mode, and it is still in Place after the relaunch.
- Steps (Core): a session in Cross Out with two undo steps. Call App.set_show_candidates(false). Then call App.set_show_candidates(true).
- Expected (Core): after the first call the session's mode is Place, the undo history still has two steps, and the saved puzzle has mode Place. After the second call the mode is still Place.

**AT-82 Marks are kept and Auto Cross works out of sight** (App)
- Steps: run SC-1 of section 4.5 on Position B, or in a real puzzle: in E cross by hand one digit ruled out in E and one that is not, then turn Show candidates off. Turn Auto Cross on from the pause menu's Settings. Place a digit d in an empty peer of E where d clashes with nothing and is open in E. Turn Show candidates on.
- Expected: with SC-1, X's ring is exactly as SC-1 step 6 states. In the real puzzle, E's two hand crosses are unchanged and keep the hand look, E's d is crossed by Auto Cross, and every other ruled out candidate of E and of every other empty cell is crossed by Auto Cross. Nothing else changed on any ring. While candidates were hidden, the Auto Cross switch could be turned on and off.

**AT-83 Undo while hidden** (App)
- Steps: run SC-2 of section 4.5 on a new puzzle with no undo steps yet: in Cross Out cross 1 in E, select F and cross 5 in F. Turn Show candidates off. Tap Undo twice, then turn Show candidates on.
- Expected: the first undo selects F and nothing else visible changes; the second selects E. Undo is then disabled. After turning it on, E's 1 and F's 5 are open and the mode is Place.

**AT-84 A hint while hidden** (App)
- Steps: Show candidates off and Auto Cross off. Start a Medium puzzle. Tap Hint until a hint names Pointing, Claiming or Naked pair, placing the digit of each placement hint (which closes it) and noting the score after each hint. With the elimination hint on screen, take a screenshot. Turn Show candidates on from the pause menu's Settings and Resume. Turn it off again and Resume. Close the hint. Then, in an empty cell, place a digit that clashes with a given in its row, so it is surely wrong (as AT-41), and tap Hint.
- Expected: every hint costs 80, the same as with the switch on. While a placement hint is on screen, no small digit shows anywhere. With the elimination hint on screen, the only small digits on the board are, in each target cell, the candidates the hint text says to cross, in the hint cross look; the target and reason cells are marked as usual. Turning the switch on shows every ring with the same highlights and no new charge; turning it off again shows only those candidates again. Closing the hint leaves no small digit anywhere. The wrong digit hint shows no small digit.

**AT-85 Lessons always show the ring** (App)
- Steps: with a puzzle in progress, turn Show candidates off. Open lesson 2 (the candidate ring) from the Lessons screen and play it through. Leave and tap Continue.
- Expected: in the lesson every empty cell shows its ring and the mode toggle shows. Crossing in Cross Out works and the lesson accepts Bart's example as AT-14 says. Back in the puzzle the rings are hidden, the toggle is hidden, and Settings still shows Show candidates off.
