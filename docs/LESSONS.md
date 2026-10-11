# Lessons

Owner: lesson-designer. Status: Phase 1 draft, matched to docs/GDD.md. This file holds the lesson outline and lesson 2, written in full as the sample. The other lessons are written in Phase 2, after Bart approves docs/GDD.md and docs/ARCHITECTURE.md defines the lesson data format.

Read with docs/BRIEF.md sections 3, 4 and 7, and docs/GDD.md sections 10.2, 11.2, 11.3 and 15.

## 1. Who the lessons are for

The lessons are for someone who has never played Sudoku. They may not know what a row, a column or a box is, and they have never seen the candidate ring. After lesson 4 they can solve every Beginner puzzle without a hint. After lesson 5 they can solve every Easy puzzle too.

A player who already knows Sudoku can skip lesson 1 and start with lesson 2, which shows how the ring and Cross Out mode work in this game. Lesson 2 repeats the rule for rows, columns and boxes in one line each, so it works without lesson 1.

## 2. How a lesson works

- A lesson is a few short screens. Each screen has a little text and a real board.
- The text explains one idea. Then the player does one step on the board: select a cell, switch the mode, cross out a digit, bring one back, or place a digit.
- The board is the real game board, with the real number pad, mode switch and Erase. What the player learns works the same way in a puzzle.
- The lesson can point at a cell or a control. This file calls that "marked". How a mark looks is a design choice.
- The player cannot fail. Every tap that is not the step's answer is a wrong tap, even selecting a different cell. A wrong tap changes nothing: not the board, the ring, the selection or the mode. It shows a short, kind explanation, and the player tries again.
- After the right tap, a short line of praise appears with a Next button. The player moves on when ready.
- Auto Cross is always off in a lesson. There is no timer, score or Hint button.

Section 8 lists these rules as decided, with their sources.

## 3. How players reach the lessons

- A Lessons screen lists every lesson in order, with its number, title and subtitle, and shows which ones the player has finished.
- Every lesson is open from the start. Any lesson can be played again at any time.
- On first launch, before the main menu, the game offers lesson 1. The player can start it or skip it. Skip opens the main menu. Lesson 1 stays on the Lessons screen for later (GDD 15.3).

## 4. Outline

> **Matches docs/GDD.md section 11.2.** Beginner needs the hidden single and allows the last empty cell. Easy adds the naked single. So lessons 3 and 4 teach everything Beginner uses, and lesson 5 adds what Easy needs. Medium, Hard and Expert have no lessons in v1.

| # | Title | Subtitle | Skill or technique it teaches | Level (GDD 11.2) | Goal | Screens |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | How Sudoku works | Rows, columns and boxes | The rules: each row, column and box holds 1 to 9 once each. Given digits cannot change. Selecting a cell and placing a digit in Place mode. | All levels | The player knows the one rule of Sudoku and can place a digit. | 6 |
| 2 | The ring and Cross Out | Cross out what a cell cannot be | The candidate ring. Cross Out mode: crossing a candidate, the X that stays visible, restoring a candidate, switching back to Place mode. | All levels | The player can cross out the digits a cell's row, column and box rule out, and bring back a digit crossed by mistake. | 8 |
| 3 | Last empty cell | When a row, column or box has one cell left | Last empty cell in a row, column or box. | Allowed at every level, needed at none | The player can spot a row, column or box with only one empty cell and fill in its missing digit. | 5 |
| 4 | Hidden single | The only spot for a digit | Hidden single, in a box, a row and a column. | Beginner | The player can find the only cell in a row, column or box where a digit can go. | 6 |
| 5 | Naked single | The last digit in the ring | Naked single. | Easy | The player can cross out a cell's ring until one digit is left, then place that digit. | 6 |
| 6 | Pointing | Stuck in one row or column | Pointing: the places for a digit inside a box all lie in one row or column. | Medium. Suggestion for Bart, not in v1 unless he approves. | The player can cross that digit out of the rest of that row or column, outside the box. | 6 |
| 7 | Claiming | Stuck in one box | Claiming: the places for a digit in a row or column all lie in one box. | Medium. Suggestion for Bart, not in v1 unless he approves. | The player can cross that digit out of the rest of that box. | 6 |
| 8 | Naked pair | Two cells, two digits | Naked pair. | Medium. Suggestion for Bart, not in v1 unless he approves. | The player can spot two cells in a group whose rings show only the same two digits, and cross those two digits out of the rest of the group. | 6 |

v1 has lessons 1 to 5. Lessons 6 to 8 are a suggestion for Bart, not in v1 unless he approves. Section 5 gives the reasons.

Notes on the plan:

- **Lesson 1.** Screens: the board and the goal; rows; columns; boxes; given digits stay put; place a first digit. The last screen uses a row with one empty cell, because that is the rule at its simplest. Lesson 3 then turns it into a technique the player looks for across the whole board, in rows, columns and boxes.
- **Lesson 2.** Written in full in section 7. It uses Bart's example from BRIEF.md section 3.
- **Lesson 3.** A row with one empty cell, then a column, then a box. Then the player finds one alone, on a board with no marks.
- **Lesson 4.** Works by looking at one digit at a time, as GDD 11.3 describes: pick a box and a digit, see which empty cells the digit's rows and columns rule out, and place the digit in the one cell left. Then the same in a row and in a column, then one the player finds alone. It needs no ring work, so Beginner can be played without notes. It also shows that a digit can have only one spot in a box even when that cell's ring still shows other digits.
- **Lesson 5.** Builds directly on the ring from lesson 2. The player crosses out what the row, column and box rule out, sees one digit left, switches to Place mode and places it. Its first screen sets it beside lesson 4: there a digit had one cell left; here a cell has one digit left.
- **Titles.** Hints name the lesson for Beginner and Easy techniques as "Lesson: Last empty cell", "Lesson: Hidden single" and "Lesson: Naked single" (GDD 10.2 and 11.2). So lessons 3 to 5 use exactly those titles. The subtitle shows under the title on the Lessons screen. "Hidden single" and "Naked single" are new words for a beginner, so the first screen of lessons 4 and 5 says what the name means in plain words before it uses it.
- **Titles of lessons 6 to 8.** If Bart approves them, they use the technique names the hints show (GDD 10.2), for the same reason.

## 5. Suggestion for Bart: lessons for Medium techniques

The GDD decides no lessons for Medium and harder techniques in v1 (GDD 11.2), and that is the plan: v1 ships lessons 1 to 5. This section is a suggestion for Bart at Hard Stop 1. Lessons 6 to 8 are not in v1 unless he approves.

**Suggestion:** add three lessons, numbered 6 to 8 in the outline, for the three techniques Medium needs: Pointing, Claiming and Naked pair. Add none for Hard or Expert.

Why add them:

1. **They show off the ring.** These are the first techniques that place nothing. They only cross digits out of rings. Crossing out is what the ring is for, so these lessons make the game's signature feature pay off.
2. **They cover the hardest jump.** Going from "find where a digit goes" to "find where a digit cannot go" is where new players tend to get stuck and quit. A short lesson at that point keeps them playing.
3. **Hints could point somewhere.** In v1 a Medium hint explains the step in place and names no lesson (GDD 11.2). With these lessons it could name one, as Beginner and Easy hints do.
4. **Low cost.** They use the same lesson player and the same screen format. The work is writing and checking boards.

Why stop at Medium:

- Techniques beyond these (X-Wing and others like it) are rare in play, need many cells with crossed digits already set up, and suit players who already study Sudoku. They add a lot of board checking for few players.
- A small v1 matters more than full coverage.

If Bart approves:

- They are written in Phase 2 after lessons 1 to 5, and they are the first thing to cut if time runs short.
- The GDD's Medium row then names them, and Medium hints show their lesson titles.
- Their boards need crossed digits already set in several cells. Lesson 2 screen 7 needs the same, so the lesson data format supports it either way.

## 6. How a screen is written in this file

- **Cells** use r1c1 notation: r5c5 is row 5, column 5. Row 1 is the top row and column 1 is the left column. Boxes are numbered 1 to 9, left to right, then top to bottom. Box 5 is the middle box: rows 4 to 6, columns 4 to 6. This notation is for the team only. Player text never uses it.
- **Boards** are 9 rows of 9 characters. A digit is a given digit. A dot is an empty cell. Every empty cell shows all nine digits in its ring, unless the screen says otherwise.

Each screen gives:

- **Board.**
- **Start state.** Which cell is selected, the number pad mode, and which digits are crossed in the ring of the cell the lesson works on.
- **Marked.** What the lesson points at.
- **Text.** The exact words the player reads.
- **Do.** What the player must do.
- **Right result.** The state after the right tap or taps.
- **After the right tap.** The praise line shown with the Next button.
- **Wrong taps.** The exact text for each likely wrong tap. `{d}` stands for the digit the player tapped. Any tap not listed gets the fallback text.
- **Author's note.** Why the answer is right, with the contents of the target cell's row, column and box.

Three rules hold on every screen:

- Every tap that is not the step's answer is a wrong tap, including selecting a different cell and tapping Erase or Undo.
- A wrong tap never changes the board, the ring, the selection or the mode.
- "The selected cell" means a tap on the cell that is already selected. A player who tries to tap a small digit in the ring lands here, because the ring cannot be tapped directly in v1.

## 7. Lesson 2: The ring and Cross Out

**Teaches:** the candidate ring and Cross Out mode. Crossing a candidate by selecting the cell and tapping that digit on the number pad. A crossed candidate stays visible with an X. Tapping the same digit again restores it. Switching back to Place mode.

**Goal:** the player can cross out the digits a cell's row, column and box rule out, and bring back a digit crossed by mistake.

**Screens:** 8.

**Uses from earlier lessons:** rows, columns, boxes, and selecting a cell (lesson 1). Each screen repeats the rule for its group in one line, so a player who skipped lesson 1 can still follow.

### The board

Every screen uses the same board. Only the ring of r5c5, the selection and the mode change.

```
3..7...9.
..8..12..
.2...6..4
8.6.4..7.
.9...3...
.5.2..3.6
..9.6..1.
1....84..
.4.5.78..
```

29 given digits. The target cell is r5c5, the middle cell of the board.

**Bart's example on this board:**

- Row 5 holds 9 (r5c2) and 3 (r5c6). Nothing else.
- Column 5 holds 4 (r4c5) and 6 (r7c5). Nothing else.
- Box 5 holds 4 (r4c5), 3 (r5c6) and 2 (r6c4). Nothing else.
- The 3 at r5c6 is in both the row and the box. The 4 at r4c5 is in both the column and the box. So five given digits make the whole example.
- Ruled out in r5c5: 2, 3, 4, 6 and 9. Still open: 1, 5, 7 and 8.

**Solution.** This full grid proves the board can be completed. Every given digit above matches it.

```
314752698
968431257
527896134
836145972
792683541
451279386
289364715
175928463
643517829
```

In the solution, r5c5 is 8, one of the four open digits.

**Legality check, done by hand.** Given digits in each group, with no repeats in any of them:

| Group | Givens | Group | Givens | Group | Givens |
| --- | --- | --- | --- | --- | --- |
| Row 1 | 3, 7, 9 | Column 1 | 3, 8, 1 | Box 1 | 3, 8, 2 |
| Row 2 | 8, 1, 2 | Column 2 | 2, 9, 5, 4 | Box 2 | 7, 1, 6 |
| Row 3 | 2, 6, 4 | Column 3 | 8, 6, 9 | Box 3 | 9, 2, 4 |
| Row 4 | 8, 6, 4, 7 | Column 4 | 7, 2, 5 | Box 4 | 8, 6, 9, 5 |
| Row 5 | 9, 3 | Column 5 | 4, 6 | Box 5 | 4, 3, 2 |
| Row 6 | 5, 2, 3, 6 | Column 6 | 1, 6, 3, 8, 7 | Box 6 | 7, 3, 6 |
| Row 7 | 9, 6, 1 | Column 7 | 2, 3, 4, 8 | Box 7 | 9, 1, 4 |
| Row 8 | 1, 8, 4 | Column 8 | 9, 7, 1 | Box 8 | 6, 8, 5, 7 |
| Row 9 | 4, 5, 7, 8 | Column 9 | 4, 6 | Box 9 | 1, 4, 8 |

The solution grid was checked the same way: every row, column and box holds 1 to 9 once each.

### Screen 1: Meet the ring

**Board:**

```
3..7...9.
..8..12..
.2...6..4
8.6.4..7.
.9...3...
.5.2..3.6
..9.6..1.
1....84..
.4.5.78..
```

**Start state:** nothing selected. Mode: Place. Ring of r5c5: all nine open.

**Marked:** r5c5.

**Text:**

> See the small digits in each empty cell? We call this the ring. It helps you keep track of which digits might still go in that cell. At the start, all nine are there. Tap the marked cell in the middle of the board.

**Do:** tap r5c5.

**Right result:** r5c5 is selected. Its row, column and box light up, as in normal play. The ring is unchanged. Mode: Place.

**After the right tap:** "Good. That cell is selected. Its row, column and box light up."

**Wrong taps:**

- Another cell: "That is a different cell. Tap the marked cell in the middle of the board."
- A digit on the number pad: "First pick a cell. Tap the marked cell in the middle of the board."
- The mode switch: "We will use that soon. First, tap the marked cell in the middle of the board."
- Fallback: "Tap the marked cell in the middle of the board."

**Author's note:** r5c5 is empty, so its ring starts with all nine digits (BRIEF.md section 3). Row 5 holds 9, 3. Column 5 holds 4, 6. Box 5 holds 4, 3, 2. Five of the nine digits are already ruled out, but nothing is crossed until the player crosses it. Screens 3 to 6 cross those five.

### Screen 2: Two modes

**Board:**

```
3..7...9.
..8..12..
.2...6..4
8.6.4..7.
.9...3...
.5.2..3.6
..9.6..1.
1....84..
.4.5.78..
```

**Start state:** r5c5 selected. Mode: Place. Ring of r5c5: all nine open.

**Marked:** the mode switch.

**Text:**

> The number pad has two modes. Place mode puts a big digit in the cell. Cross Out mode puts an X on a small digit in the ring. Tap the mode switch to choose Cross Out.

**Do:** tap the mode switch.

**Right result:** mode is Cross Out. r5c5 stays selected. The ring is unchanged.

**After the right tap:** "Good. The number pad is in Cross Out mode now."

**Wrong taps:**

- A digit on the number pad: "In Place mode, that would put a big digit in the cell. Tap the mode switch first."
- The selected cell: "This cell is ready. Now tap the mode switch."
- Another cell: "Keep this cell selected. Tap the mode switch."
- Fallback: "Tap the mode switch to choose Cross Out."

**Author's note:** no digit is the answer here. Row 5 holds 9, 3. Column 5 holds 4, 6. Box 5 holds 4, 3, 2. That leaves four open digits (1, 5, 7, 8), so placing any digit in r5c5 now would be a guess. That is why a digit tap in Place mode is a wrong tap on this screen.

### Screen 3: Cross out a digit

**Board:**

```
3..7...9.
..8..12..
.2...6..4
8.6.4..7.
.9...3...
.5.2..3.6
..9.6..1.
1....84..
.4.5.78..
```

**Start state:** r5c5 selected. Mode: Cross Out. Ring of r5c5: all nine open.

**Marked:** r5c2 (the 9 in the row).

**Text:**

> A row can have each digit only once. This row already has a 9. So this cell cannot be 9. Tap 9 on the number pad to cross it out.

**Do:** tap 9 on the number pad.

**Right result:** 9 in the ring of r5c5 is crossed. It stays visible with an X over it.

**After the right tap:** "Well done. You crossed out 9."

**Wrong taps:**

- 3: "Yes, this row has a 3 too. We will cross it out next. Tap 9 first."
- 4 or 6: "Yes, this column has a {d}. We will get to the column soon. Tap 9 first."
- 2: "Yes, this box has a 2. We will get to the box soon. Tap 9 first."
- 1, 5, 7 or 8: "There is no {d} in this row, column or box. So {d} can still go here. Tap 9."
- The selected cell: "The small digits are too small to tap. Tap 9 on the number pad instead."
- The marked 9 (r5c2): "That is the 9 in the row. To cross out 9 in the ring, tap 9 on the number pad."
- Another cell: "Keep this cell selected. Tap 9 on the number pad."
- The mode switch: "Stay in Cross Out mode for now. Tap 9 on the number pad."
- Fallback: "Tap 9 on the number pad."

**Author's note:** row 5 holds 9 (r5c2) and 3 (r5c6), so 9 is ruled out by the row. Column 5 holds 4 (r4c5) and 6 (r7c5). Box 5 holds 4 (r4c5), 3 (r5c6) and 2 (r6c4). Each wrong tap message is true: 3 is in row 5; 4 and 6 are in column 5; 2 is in box 5 only; 1, 5, 7 and 8 are in none of the three groups.

### Screen 4: The X stays

**Board:**

```
3..7...9.
..8..12..
.2...6..4
8.6.4..7.
.9...3...
.5.2..3.6
..9.6..1.
1....84..
.4.5.78..
```

**Start state:** r5c5 selected. Mode: Cross Out. Ring of r5c5: 9 crossed, the rest open.

**Marked:** r5c6 (the 3 in the row).

**Text:**

> See the X on the 9? It stays in the ring, so you can always see what you ruled out. This row also has a 3. Cross out 3 too.

**Do:** tap 3 on the number pad.

**Right result:** ring of r5c5: 3 and 9 crossed, the rest open.

**After the right tap:** "Good. 9 and 3 are both crossed out."

**Wrong taps:**

- 9: "9 already has an X. Tapping it again would bring it back. Tap 3."
- 4 or 6: "Yes, this column has a {d}. We will get to the column next. Tap 3 first."
- 2: "Yes, this box has a 2. We will get to the box soon. Tap 3 first."
- 1, 5, 7 or 8: "There is no {d} in this row, column or box. So {d} can still go here. Tap 3."
- The selected cell: "The small digits are too small to tap. Tap 3 on the number pad instead."
- The marked 3 (r5c6): "That is the 3 in the row. To cross out 3 in the ring, tap 3 on the number pad."
- Another cell: "Keep this cell selected. Tap 3 on the number pad."
- The mode switch: "Stay in Cross Out mode for now. Tap 3 on the number pad."
- Fallback: "Tap 3 on the number pad."

**Author's note:** row 5 holds 9 (r5c2) and 3 (r5c6), so 3 is ruled out by the row. The same 3 also sits in box 5. Column 5 holds 4 (r4c5) and 6 (r7c5). Box 5 holds 4 (r4c5), 3 (r5c6) and 2 (r6c4). Tapping 9 here would restore it, which is why it is a wrong tap.

### Screen 5: The column

**Board:**

```
3..7...9.
..8..12..
.2...6..4
8.6.4..7.
.9...3...
.5.2..3.6
..9.6..1.
1....84..
.4.5.78..
```

**Start state:** r5c5 selected. Mode: Cross Out. Ring of r5c5: 3 and 9 crossed, the rest open.

**Marked:** r4c5 (the 4) and r7c5 (the 6).

**Text:**

> A column can have each digit only once, too. This column has a 4 and a 6. Cross out 4 and 6.

**Do:** tap 4 and 6 on the number pad, in either order. After the first of the two, its X appears and the screen waits for the other.

**Right result:** ring of r5c5: 3, 4, 6 and 9 crossed. 1, 2, 5, 7 and 8 open.

**After the right tap:** "Nice work. The column is done."

**Wrong taps.** `{next}` is "Cross out 4 and 6." before either is crossed, "Now cross out 6." once 4 is crossed, and "Now cross out 4." once 6 is crossed.

- 3 or 9, or 4 or 6 once it has an X: "{d} already has an X. Tapping it again would bring it back. {next}"
- 2: "Yes, this box has a 2. We will get to the box next. {next}"
- 1, 5, 7 or 8: "There is no {d} in this row, column or box. So {d} can still go here. {next}"
- The selected cell: "The small digits are too small to tap. Use the number pad. {next}"
- The marked 4 (r4c5): "That is the 4 in the column. Use the number pad to cross out digits. {next}"
- The marked 6 (r7c5): "That is the 6 in the column. Use the number pad to cross out digits. {next}"
- Another cell: "Keep this cell selected. {next}"
- The mode switch: "Stay in Cross Out mode for now. {next}"
- Fallback: "{next}"

**Author's note:** column 5 holds 4 (r4c5) and 6 (r7c5), so both are ruled out by the column. Row 5 holds 9 (r5c2) and 3 (r5c6). Box 5 holds 4 (r4c5), 3 (r5c6) and 2 (r6c4). The other cells of column 5 (r1c5, r2c5, r3c5, r6c5, r8c5, r9c5) are empty.

### Screen 6: The box

**Board:**

```
3..7...9.
..8..12..
.2...6..4
8.6.4..7.
.9...3...
.5.2..3.6
..9.6..1.
1....84..
.4.5.78..
```

**Start state:** r5c5 selected. Mode: Cross Out. Ring of r5c5: 3, 4, 6 and 9 crossed. 1, 2, 5, 7 and 8 open.

**Marked:** r4c5 (the 4), r5c6 (the 3) and r6c4 (the 2).

**Text:**

> A box can have each digit only once as well. This box has a 2, a 3 and a 4. You already crossed out 3 and 4. Cross out 2.

**Do:** tap 2 on the number pad.

**Right result:** ring of r5c5: 2, 3, 4, 6 and 9 crossed. 1, 5, 7 and 8 open.

**After the right tap:** "Great. Only 1, 5, 7 and 8 are still open. One of them is the right digit for this cell."

**Wrong taps:**

- 3, 4, 6 or 9: "{d} already has an X. Tapping it again would bring it back. Tap 2."
- 1, 5, 7 or 8: "There is no {d} in this row, column or box. So {d} can still go here. Tap 2."
- The selected cell: "The small digits are too small to tap. Tap 2 on the number pad instead."
- The marked 2 (r6c4): "That is the 2 in the box. To cross out 2 in the ring, tap 2 on the number pad."
- The marked 3 (r5c6) or the marked 4 (r4c5): "That digit is in the box, and it already has an X in the ring. Tap 2 on the number pad."
- Another cell: "Keep this cell selected. Tap 2 on the number pad."
- The mode switch: "Stay in Cross Out mode for now. Tap 2 on the number pad."
- Fallback: "Tap 2 on the number pad."

**Author's note:** box 5 (rows 4 to 6, columns 4 to 6) holds 4 (r4c5), 3 (r5c6) and 2 (r6c4). Its other cells (r4c4, r4c6, r5c4, r6c5, r6c6) are empty. So 2 is ruled out by the box. Row 5 holds 9 (r5c2) and 3 (r5c6). Column 5 holds 4 (r4c5) and 6 (r7c5). All three groups together rule out 2, 3, 4, 6 and 9, which leaves 1, 5, 7 and 8. The solution has 8 in r5c5, so the praise line is true.

### Screen 7: Bring a digit back

**Board:**

```
3..7...9.
..8..12..
.2...6..4
8.6.4..7.
.9...3...
.5.2..3.6
..9.6..1.
1....84..
.4.5.78..
```

**Start state:** r5c5 selected. Mode: Cross Out. Ring of r5c5: 2, 3, 4, 6, 7 and 9 crossed. 1, 5 and 8 open. The lesson sets the cross on 7 at the start of this screen.

**Marked:** r5c5.

**Text:**

> Everyone taps the wrong digit sometimes. To show you the fix, we crossed out 7 for you. But there is no 7 in this row, column or box, so 7 can still go here. Tap 7 to bring it back.

**Do:** tap 7 on the number pad.

**Right result:** ring of r5c5: 2, 3, 4, 6 and 9 crossed. 1, 5, 7 and 8 open.

**After the right tap:** "7 is back. Tap a crossed digit again any time to bring it back."

**Wrong taps:**

- 1, 5 or 8: "That would cross out {d}. But there is no {d} in this row, column or box, so leave it open. Tap 7."
- 3 or 9: "Leave the X on {d}. This row has a {d}, so this cell cannot be {d}. Tap 7."
- 4 or 6: "Leave the X on {d}. This column has a {d}, so this cell cannot be {d}. Tap 7."
- 2: "Leave the X on 2. This box has a 2, so this cell cannot be 2. Tap 7."
- The selected cell: "The small digits are too small to tap. Tap 7 on the number pad instead."
- Another cell: "Keep this cell selected. Tap 7 on the number pad."
- The mode switch: "Stay in Cross Out mode for now. Tap 7 on the number pad."
- Fallback: "Tap 7 on the number pad."

**Author's note:** row 5 holds 9 (r5c2) and 3 (r5c6). Column 5 holds 4 (r4c5) and 6 (r7c5). Box 5 holds 4 (r4c5), 3 (r5c6) and 2 (r6c4). 7 is in none of them, so the cross on 7 was wrong and restoring it is right. The lesson sets the cross itself instead of asking the player to make a mistake on purpose. That way every step the player takes is a correct one, and the lesson data test can check every step the same way.

### Screen 8: Back to Place mode

**Board:**

```
3..7...9.
..8..12..
.2...6..4
8.6.4..7.
.9...3...
.5.2..3.6
..9.6..1.
1....84..
.4.5.78..
```

**Start state:** r5c5 selected. Mode: Cross Out. Ring of r5c5: 2, 3, 4, 6 and 9 crossed. 1, 5, 7 and 8 open.

**Marked:** the mode switch.

**Text:**

> To put a big digit in a cell, you need Place mode. Tap the mode switch to go back to Place mode.

**Do:** tap the mode switch.

**Right result:** mode is Place. r5c5 stays selected and empty. The ring is unchanged.

**After the right tap:** "Well done. You are back in Place mode, and you know how the ring works."

**Wrong taps:**

- A digit on the number pad: "In Cross Out mode, that would change the ring. Tap the mode switch to go back to Place mode."
- The selected cell or another cell: "Tap the mode switch to go back to Place mode."
- Fallback: "Tap the mode switch to go back to Place mode."

**Author's note:** no digit is placed in this lesson. Row 5 holds 9, 3. Column 5 holds 4, 6. Box 5 holds 4, 3, 2. That leaves four open digits in r5c5 (1, 5, 7, 8), and choosing between them needs lessons 4 and 5.

## 8. Decisions on lesson behavior

These shape how every lesson behaves. The Development Manager settled each one on 2026-10-11.

1. **Auto Cross is always off in a lesson,** whatever the setting says (GDD 15.4). Lesson 2 could not work otherwise, because Auto Cross would cross 2, 3, 4, 6 and 9 before the player does.
2. **Every tap that is not the step's answer is a wrong tap,** including selecting a different cell. A wrong tap changes nothing: not the board, the ring, the selection or the mode. It shows the screen's explanation, and the player tries again. Lessons are scripted around one cell, so every tap teaches something. This replaces "selecting a cell is never wrong" in GDD 15.4 and AT-63; the GDD is being updated to match.
3. **After the right answer,** a praise line and a Next button appear. The screen does not move on by itself.
4. **No timer, score or hints in a lesson** (GDD 15.4 and 10.4). A tap on Erase or Undo that is not the step's answer gets the screen's fallback text.
5. **Every lesson is open from the start.** Leaving a lesson part way through means it starts again at screen 1 next time. A lesson counts as finished when the player completes the answer of its last step (GDD 15.4), even if they leave before tapping the last Next.
6. **Bart's example as five given digits.** In lesson 2 the 3 is one cell shared by the row and the box, and the 4 is one cell shared by the column and the box. GDD 4.4 (Position B) uses seven given digits, with separate cells for those. Both rule out the same five digits and leave 1, 5, 7 and 8 open.
7. **Lesson 1 overlaps lesson 3 a little.** Lesson 1's last screen fills a row with one empty cell. That is accepted: lesson 3 turns it into a technique.
8. **The lesson validity test checks for at least one solution,** not exactly one. Lesson boards are legal and can be completed, but they are not puzzles with a single solution. This goes into ARCHITECTURE.md in Phase 2.
9. **The lesson data format** is defined in ARCHITECTURE.md in Phase 2. This list is the input for it: a start board; a start selection; a start mode; digits already crossed in a cell's ring at the start of a screen; marked cells and marked controls; a goal of one tap or several taps in any order; the praise line; wrong tap texts by digit, by cell and by control, with `{d}`; and a fallback text.
