# Sudoku: Game Design Document

Owner: lead-game-designer. Approved by Bart at Hard Stop 1, 2026-10-11. Where this document disagrees with docs/BRIEF.md, the brief wins, unless Bart decided otherwise (CLAUDE.md, "Decisions from Bart after the brief").

Change log: 2026-10-11, Phase 2: updated for Bart's Hard Stop 1 decisions (his answers to the three questions, the New best rule in 12.1 with AT-67, a hand-crossed digit drawn on top of its X, ring layout A, the Pop light and Pop dark skins, the screen sizes in AT-66), and corrected the example scores in section 13 and AT-53 to match the score formula. Later in Phase 2: added the Settings line for Auto Cross (5.2), and the rule that taps after a lesson step's answer are ignored until Next (15.4, AT-63). 2026-10-12, Phase 3: updated for Bart's Hard Stop 2 decisions: a givens floor for Beginner and Easy (11.4, AT-68) and the hint highlight of candidates to cross (2.3, 10.2, AT-69).

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

Play
- Undo: one step per place, replace, erase, cross or restore, with no limit, back to the start of the puzzle. Undo selects the cell it changes. The history survives closing the app. [7]
- A full board with a clash does not complete. A short message says so and the timer keeps running. [6]
- The timer runs only while the board is on screen. The pause menu hides the board. Coming back from the background opens the pause menu. [8]
- Points: Beginner 100, Easy 200, Medium 400, Hard 700, Expert 1000. Hint cost: 20, 40, 80, 140, 200. [9, 10]
- Five levels: Beginner, Easy, Medium, Hard, Expert, all open from the start. [11]
- Beginner puzzles have at least 36 givens and Easy at least 32, so they look gentler. Givens still never decide the level. No symmetric givens in v1. [11]
- A hint that crosses candidates also highlights, in each target cell, the candidates to cross that still show open. [10]
- Beginner and Easy need only last empty cell, hidden single and naked single, which is what the lesson plan teaches. [11]
- No lessons for Medium and harder techniques in v1, as Bart confirmed: v1 has lessons 1 to 5. Hints explain those techniques. [11]
- Completion locks the board and shows level, time, and the score with its parts, plus a New best label when the result beats the level's previous best. [12]
- Stats are exactly the brief's list. [13]
- Starting a puzzle while one is in progress asks once for confirmation. First launch offers lesson 1 once. [15]
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
- Every empty cell shows its ring (section 4). A cell holding a digit hides its ring.

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

## 3. Input model

### 3.1 Controls

Number pad 1 to 9, a mode toggle with Place and Cross Out (it always shows which is on), Erase and Undo. The Hint button is in the HUD (section 10). Erase and Undo do the same thing in both modes.

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

A crossed digit always stays visible and readable. A digit crossed by hand is drawn on top of its X with a thin outline, so the digit reads clearly and the X still shows around it. Bart approved this at Hard Stop 1, and it replaces the brief's "X drawn over it". How the Auto Cross X differs from the hand X is in section 5.2. The senior graphic designer owns the exact drawing of both.

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

Not undo steps: selecting a cell, switching modes, taps where nothing happens, buying a hint, turning Auto Cross on or off, pausing.

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
- Example: the player places 5 in E and crosses 2 in F, then a phone call pushes the game out and Android closes it. The player reopens and taps Continue. Undo restores F's 2, then empties E.

## 8. Timer and pause

- The timer starts at 0:00 when a new puzzle's board first appears. Time spent generating the puzzle is not counted.
- It runs only while the puzzle screen is showing with nothing over the board. The hint panel and the full board message do not stop it.
- It pauses while the pause menu is open (including Settings opened from it), while the app is in the background or has lost focus, and while the player is on any other screen (main menu, lessons, stats) with a puzzle in progress.
- When the app comes back from the background during a puzzle, the pause menu is showing. The timer resumes when the player taps Resume.
- Android Back on the puzzle screen opens the pause menu. Back in the pause menu resumes.
- It stops for good at completion.
- It counts whole seconds, shown as m:ss, or h:mm:ss from one hour. The final time t is the whole seconds at completion.
- It is saved with the puzzle. After a restart it continues from the saved value. Time while the app is closed never counts.

Decision: the pause menu covers the board.
- Reason: paused time should not be thinking time.
- Example: at 4:12 the player opens the pause menu, studies nothing because the board is hidden, and resumes at 4:12.

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
| Settings | Sound (default on), skin (one of the two built-in skins, Pop light or Pop dark; default Pop light), Auto Cross (default off) | When changed | Never |
| Stats | Section 13 | At puzzle start, completion and Reset Stats | Cleared by Reset Stats |
| Lesson progress | Which lessons were finished | When a lesson is finished the first time | Never |
| First launch | Whether the lesson 1 offer was answered | When answered | Never |

- Not saved: a lesson in progress (it restarts from its first screen) and the full board message.
- If the app dies without warning, no board change is lost, because each one is saved at once. At most the timer seconds since the last save are lost.
- If saved data cannot be read or fails validation, that part falls back to its default (for the puzzle: none in progress), the other parts load normally, and the game does not crash.

## 15. New puzzle, first launch and lessons

### 15.1 App start

The app opens on the main menu, except on first launch (15.3). If a puzzle is in progress, Continue is the first button. It opens the puzzle with the saved cell selected, the saved mode on and the timer running.

### 15.2 Starting a new puzzle

- New puzzle opens level select: five levels, all open.
- With no puzzle in progress, the chosen level starts at once, after generation.
- With a puzzle in progress, a dialog asks: "You have a {level} puzzle in progress. Start a new {chosen level} puzzle? The current one will count as started, not completed." Buttons: Keep playing and Start new.
- Keep playing returns to the puzzle in progress with nothing changed.
- Start new abandons the old puzzle: it and its undo history are deleted and stats do not change. Then the new puzzle is generated, and when its board appears its level's Started goes up by 1.
- Play again on the completion screen starts a new puzzle at the same level with no dialog.

### 15.3 First launch

- The first time the app opens, before the main menu, it offers lesson 1: "New to Sudoku? Lesson 1 shows you how to play." Buttons: Start lesson and Skip.
- Start lesson opens lesson 1. Skip opens the main menu.
- Either answer is final, and the offer never shows again. If the app closes before the player answers, it shows again next time.
- Lesson 1 is always available from the Lessons screen.

### 15.4 Lessons and the game rules

LESSONS.md holds the lesson content. These rules apply to every lesson:
- Lessons use the same board, selection, Place and Cross Out modes and Erase as puzzles.
- Auto Cross is always off in lessons, whatever the setting, because lessons teach crossing by hand.
- No timer, score, hints or puzzle stats in lessons. A puzzle in progress stays saved and untouched, and its timer does not run.
- Until the step's answer is complete, every tap that is not part of it, as LESSONS.md defines it, is a wrong tap. That includes selecting a different cell. A wrong tap changes nothing (board, ring, selection and mode stay as they were), the lesson's short explanation shows, and the player tries again. The player cannot fail.
- Reason: lessons are scripted around one cell, so this keeps the player on the taught cell and makes every tap teach.
- Once the step's answer is complete, the praise line and Next show. Every other tap on the board, the pad and the controls is ignored, with no text, until the player taps Next.
- Reason: a wrong tap text is written for the step in progress. After the answer it would be out of date, for example "Pick the cell first" once the digit is already placed.
- A lesson counts as finished when the player completes its last step. Leaving early does not count.
- Example: in the candidate ring lesson, on Bart's example, the player in Cross Out mode taps 5. 5 stays open, a short note explains that nothing in the row, column or box holds a 5, and the step waits for the right taps.

## 16. Acceptance tests

How to read them:
- Core: a unit test on the stated position, in tests/core or tests/puzzles. App: checked by hand in the running game.
- Unless a test says otherwise: settings at their defaults (sound on, Pop light skin, Auto Cross off) and a new Beginner puzzle.
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
- Steps: buy a hint. Kill the app. Reopen and tap Continue.
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
- Steps: note Easy's Started. Start an Easy puzzle. Check Stats. Leave, tap Continue, check again. Kill the app, reopen, Continue, check again.
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
- Steps: Auto Cross on. Mid puzzle, have placed digits, hand crosses, hand restores, Auto Cross crosses, one hint bought and closed, Cross Out mode on, a cell selected, about 3 minutes on the timer, and several undo steps. Send the app to the background and swipe it away (or force-stop it). Reopen and tap Continue. Then undo step by step. Repeat once with a force-stop right after an action, without going to the background first.
- Expected: every digit, every candidate with its exact state and look, the score, the mode and the selected cell are as they were. The timer is within one second of its value when the app went to the background. Undo works back to the start of the puzzle. After the force-stop variant, the last action is there.

**AT-58 Settings persist** (App)
- Steps: fresh install. Open Settings and look at the skin picker. Turn sound off, pick Pop dark, turn Auto Cross on. Kill the app and reopen.
- Expected: the skin picker offers exactly two skins, Pop light and Pop dark, with Pop light selected on the fresh install. After reopening, all three settings are as set and the game shows Pop dark.

**AT-59 Stats and lesson progress persist** (App)
- Steps: after AT-53 and AT-56, kill the app and reopen.
- Expected: stats and lessons completed are unchanged.

**AT-60 Damaged save** (Core, App)
- Steps: replace the saved puzzle with unreadable data. Then with readable data holding impossible values (a digit 12, a cell index 99, a negative timer). Start the game each time.
- Expected: the game starts without crashing and shows no puzzle in progress. Settings, stats and lesson progress load normally.

### Flow and lessons

**AT-61 New puzzle while one is in progress** (App)
- Steps: with a puzzle in progress, tap New puzzle and choose Hard. Tap Keep playing. Do it again and tap Start new. Then, with no puzzle in progress, tap New puzzle and choose Easy.
- Expected: level select shows five levels, all open. The dialog names both levels. Keep playing returns to the old puzzle unchanged. Start new abandons it as AT-54 describes and starts a Hard puzzle. With nothing in progress, Easy starts with no dialog.

**AT-62 First launch** (App)
- Steps: fresh install. Launch. Kill the app before answering. Launch again and tap Skip. Kill and launch again. Open the Lessons screen. Then fresh install again, launch and tap Start lesson.
- Expected: the offer shows on the first launch and again after the kill. Skip opens the main menu, and the offer never shows again. Lesson 1 is in the Lessons screen. Start lesson opens lesson 1.

**AT-63 Lesson wrong answers** (App)
- Steps: in a lesson step, do each of these wrong taps in turn: select a different cell; with the taught cell selected, tap a wrong digit; in a Cross Out step, cross a candidate that should stay open; tap the mode toggle when switching is not part of the answer. Then do the right taps.
- Expected: each wrong tap changes nothing: the board, the ring, the selection and the mode stay as they were. The lesson's short explanation shows and the step stays. Selecting another cell leaves the taught cell selected. There is no way to fail. The right taps move the lesson on, and finishing the last step's answer counts the lesson as finished.
- Steps, part 2: complete a step's answer, and before tapping Next, tap a different cell, a digit, the mode toggle, Erase and Undo.
- Expected, part 2: the praise line and Next stay. Nothing changes on the board, the ring, the selection or the mode, and no explanation shows. Tapping Next moves on.

**AT-64 Lessons and the puzzle in progress** (App)
- Steps: Auto Cross on and a puzzle in progress at 2:00. Open a lesson that has empty cells next to digits and spend a minute in it. Leave and tap Continue.
- Expected: no candidate in the lesson is crossed by Auto Cross. The lesson shows no timer, score or Hint button. The puzzle in progress is unchanged and its timer still shows 2:00.

**AT-65 Rotation lock** (App, on a phone)
- Steps: with auto-rotate on, turn the phone to landscape on the main menu, during a puzzle, in a lesson and with a dialog open.
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
