# Lessons

Owner: lesson-designer. Status: Phase 2. All five v1 lessons are written in full in section 7. Bart approved docs/GDD.md at Hard Stop 1 on 2026-10-11 and decided that v1 has lessons 1 to 5 only. The lesson data files in src/lessons/data/ come next, in the format of docs/ARCHITECTURE.md section 10.

Read with docs/BRIEF.md sections 3, 4 and 7, and docs/GDD.md sections 2, 3, 4, 10.2, 11.2, 11.3 and 15.

## 1. Who the lessons are for

The lessons are for someone who has never played Sudoku. They may not know what a row, a column or a box is, and they have never seen the candidate ring. After lesson 4 they can solve every Beginner puzzle without a hint. After lesson 5 they can solve every Easy puzzle too.

A player who already knows Sudoku can skip lesson 1 and start with lesson 2, which shows how the ring and Cross Out mode work in this game. Lesson 2 repeats the rule for rows, columns and boxes in one line each, so it works without lesson 1.

## 2. How a lesson works

- A lesson is a few short screens. Each screen has a little text and a real board.
- The text explains one idea. Then the player does one step on the board: select a cell, switch the mode, cross out a digit, bring one back, or place a digit. Some screens ask for two steps in a row, such as tapping a cell and then placing a digit there.
- The board is the real game board, with the real number pad, mode switch and Erase. What the player learns works the same way in a puzzle.
- The lesson can point at a cell or a control. This file calls that "marked". How a mark looks is a design choice.
- The player cannot fail. Every tap that is not the step's answer is a wrong tap, even selecting a different cell. A wrong tap changes nothing: not the board, the ring, the selection or the mode. It shows a short, kind explanation, and the player tries again.
- After the right tap, a short line of praise appears with a Next button. Until the player taps Next, every other tap is ignored. The player moves on when ready.
- Auto Cross is always off in a lesson. There is no timer, score or Hint button.

Section 8 lists these rules as decided, with their sources.

## 3. How players reach the lessons

- A Lessons screen lists every lesson in order, with its number, title and subtitle, and shows which ones the player has finished.
- Every lesson is open from the start. Any lesson can be played again at any time.
- The game offers lesson 1 the first time the player taps PLAY on the title screen (GDD 15.0 and 15.3). The offer reads "New to Sudoku? Lesson 1 shows you how to play." Its buttons are Start lesson and Skip.
- Start lesson opens lesson 1 over the main menu, so leaving the lesson shows the main menu.
- Skip goes straight into a puzzle, just like PLAY: the puzzle in progress if there is one, else a new puzzle at the last level started (Easy the first time).
- Either answer is final, and the offer never shows again. Android Back on the offer returns to the title screen without answering it, so the next PLAY shows the offer again. So does the next PLAY if the app closes before the player answers.
- Lesson 1 stays on the Lessons screen for later.

## 4. Outline

> **Matches docs/GDD.md section 11.2.** Beginner needs the hidden single and allows the last empty cell. Easy adds the naked single. So lessons 3 and 4 teach everything Beginner uses, and lesson 5 adds what Easy needs. Medium, Hard and Expert have no lessons in v1.

| # | Title | Subtitle | Skill or technique it teaches | Level (GDD 11.2) | Goal | Screens |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | How Sudoku works | Rows, columns and boxes | The rules: each row, column and box holds 1 to 9 once each. Given digits cannot change. Selecting a cell and placing a digit in Place mode. | All levels | The player knows the one rule of Sudoku and can place a digit. | 6 |
| 2 | The ring and Cross Out | Cross out what a cell cannot be | The candidate ring. Cross Out mode: crossing a candidate, the X that stays visible, restoring a candidate, switching back to Place mode. | All levels | The player can cross out the digits a cell's row, column and box rule out, and bring back a digit crossed by mistake. | 8 |
| 3 | Last empty cell | When a row, column or box has one cell left | Last empty cell in a row, column or box, and how one placed digit can open up the next. | Allowed at every level, needed at none | The player can spot a row, column or box with only one empty cell and fill in its missing digit. | 5 |
| 4 | Hidden single | The only spot for a digit | Hidden single, in a box, a row and a column. Tapping a digit to light up all its copies. | Beginner | The player can find the only cell in a row, column or box where a digit can go. | 6 |
| 5 | Naked single | The last digit in the ring | Naked single. | Easy | The player can cross out a cell's ring until one digit is left, then place that digit. | 6 |

v1 has lessons 1 to 5, as Bart decided at Hard Stop 1 on 2026-10-11. Together they have 31 screens. Section 5 notes the lessons that were left out.

Notes on the plan:

- **Lesson 1.** Screens: the board and the goal; rows; columns; boxes; given digits stay put; place a first digit. Screens 2 to 4 each mark a row, a column or a box with one empty cell, and the player taps that cell, so its row, column and box light up. The last screen fills the row from screen 2, because that is the rule at its simplest. Lesson 3 then turns it into a technique the player looks for across the whole board, in rows, columns and boxes.
- **Lesson 2.** Written in full in section 7.2. It uses Bart's example from BRIEF.md section 3.
- **Lesson 3.** A row with one empty cell, then a column, then a box. Then the player finds one alone, on a board with no marks. Last, the player sees that the digit just placed left another box with one empty cell, and fills that too. All five screens share one board.
- **Lesson 4.** Works by looking at one digit at a time, as GDD 11.3 describes: pick a box and a digit, see which empty cells the digit's copies rule out, and place the digit in the one cell left. Screen 2 shows that cell's ring with four digits still open, so the player sees why it is not a naked single. Then the same in a row and in a column. Then a tip: tapping a digit on the board lights up all its copies (GDD 2.3). Then one the player finds alone. It needs no ring work, so Beginner can be played without notes.
- **Lesson 5.** Builds directly on the ring from lesson 2. The player crosses out what the row, then the column, then the box rule out, sees one digit left, switches to Place mode and places it. Its first screen sets it beside lesson 4: there a digit had one cell left; here a cell has one digit left.
- **Titles.** Hints name the lesson for Beginner and Easy techniques as "Lesson: Last empty cell", "Lesson: Hidden single" and "Lesson: Naked single" (GDD 10.2 and 11.2). So lessons 3 to 5 use exactly those titles. The subtitle shows under the title on the Lessons screen. "Hidden single" and "Naked single" are new words for a beginner, so the first screen of lessons 4 and 5 says what the name means in plain words.

## 5. Lessons for Medium techniques: not in v1

Three more lessons were considered, for the techniques Medium needs: Pointing, Claiming and Naked pair. Bart decided at Hard Stop 1, on 2026-10-11, that v1 has lessons 1 to 5 only, so they are left out. As GDD 11.2 says, a Medium hint explains its technique in place and names no lesson. These lessons could come in a later version.

## 6. How a screen is written in this file

- **Cells** use r1c1 notation: r5c5 is row 5, column 5. Row 1 is the top row and column 1 is the left column. Boxes are numbered 1 to 9, left to right, then top to bottom. Box 5 is the middle box: rows 4 to 6, columns 4 to 6. This notation is for the team only. Player text never uses it.
- **Boards** are 9 rows of 9 characters. A digit is a given digit. A dot is an empty cell. Every empty cell shows all nine digits in its ring, unless the screen says otherwise.
- **A marked row, column or box** means all nine of its cells are marked.

Each screen gives:

- **Board.** The given digits only.
- **Start state.** Which cell is selected, the number pad mode, which digits are crossed in the ring of the cell the lesson works on, and "Placed": the digits the player placed on earlier screens of the same lesson. They stay on the board as the player's own digits, not as givens.
- **Marked.** What the lesson points at.
- **Text.** The exact words the player reads.
- **Do.** What the player must do: one tap, several taps in any order, or a few taps in a fixed order (for example, tap a cell, then place a digit in it).
- **Technique.** Only on a screen whose answer places a digit. The technique from GDD 11.3 that proves the placement, by its code name (`last_empty_cell`, `hidden_single` or `naked_single`), and the group where it applies. The board, with the placed digits, lets that technique find that cell and digit among its placements, using only what the player has been taught by then. The technique may find other placements too; the screen's marks and text make the answer unique. The lesson data test checks the same thing (ARCHITECTURE.md section 10).
- **Right result.** The state after the right tap or taps.
- **After the right tap.** The praise line shown with the Next button, after the last tap of the answer.
- **Wrong taps.** The exact text for each likely wrong tap. `{d}` stands for the digit the player tapped. `{next}` stands for a short reminder of what to do now; where a screen uses it, the screen says what it reads before and after the first tap. Any tap not listed gets the fallback text. On a screen with taps in a fixed order, a tap that belongs to a later part of the answer is a wrong tap until its turn.
- **Author's note.** Why the answer is right, with the contents of the target cell's row, column and box.

Three rules hold on every screen:

- Every tap that is not the step's answer is a wrong tap, including selecting a different cell and tapping Erase or Undo.
- A wrong tap never changes the board, the ring, the selection or the mode.
- "The selected cell" means a tap on the cell that is already selected. A player who tries to tap a small digit in the ring lands here, because the ring cannot be tapped directly in v1.

## 7. The lessons

The five lessons, in order. Every board in them completes to the same full grid, the one below. Lesson 2's board was built on it first, and lessons 1, 3, 4 and 5 take their given digits from it too. So every board is legal by construction: its digits are part of a finished grid, so no digit repeats in a row, column or box, and the board can be completed. Each board is still checked group by group, by hand, in its own lesson, and each lesson repeats the grid as its solution.

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

Checked by hand: every row, every column and every box of this grid holds 1 to 9 once each.

### 7.1 Lesson 1: How Sudoku works

**Teaches:** the rules of Sudoku. A row goes across, a column goes down, and a box is 3 by 3 cells. Each row, column and box holds 1 to 9 once each. Given digits are locked. Selecting a cell, and placing a digit in Place mode.

**Goal:** the player knows the one rule of Sudoku and can place a digit.

**Screens:** 6.

**Uses from earlier lessons:** nothing. This is the first lesson, and the game offers it the first time the player taps PLAY on the title screen (GDD 15.3).

**Mode:** Place on every screen. Lesson 1 does not explain the mode switch; lesson 2 does.

#### The board

Every screen uses the same board. Only the selection, the marks and, on screen 6, the placed digit change.

```
31..5..9.
.6.4..2.7
5.7.9..3.
.3.1.5972
79...35.1
.51.7.386
.8.3..7.5
17592.463
64.5.7..9
```

46 given digits. Exactly three groups have only one empty cell, one for each of screens 2 to 4: row 8 (r8c6), column 2 (r3c2) and box 6 (r5c8). Every other row, column and box has two or more empty cells.

**Solution.** The grid from the start of section 7. Every given digit above matches it.

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

**Legality check, done by hand.** Given digits in each group, with no repeats in any of them:

| Group | Givens | Group | Givens | Group | Givens |
| --- | --- | --- | --- | --- | --- |
| Row 1 | 3, 1, 5, 9 | Column 1 | 3, 5, 7, 1, 6 | Box 1 | 3, 1, 6, 5, 7 |
| Row 2 | 6, 4, 2, 7 | Column 2 | 1, 6, 3, 9, 5, 8, 7, 4 | Box 2 | 5, 4, 9 |
| Row 3 | 5, 7, 9, 3 | Column 3 | 7, 1, 5 | Box 3 | 9, 2, 7, 3 |
| Row 4 | 3, 1, 5, 9, 7, 2 | Column 4 | 4, 1, 3, 9, 5 | Box 4 | 3, 7, 9, 5, 1 |
| Row 5 | 7, 9, 3, 5, 1 | Column 5 | 5, 9, 7, 2 | Box 5 | 1, 5, 3, 7 |
| Row 6 | 5, 1, 7, 3, 8, 6 | Column 6 | 5, 3, 7 | Box 6 | 9, 7, 2, 5, 1, 3, 8, 6 |
| Row 7 | 8, 3, 7, 5 | Column 7 | 2, 9, 5, 3, 7, 4 | Box 7 | 8, 1, 7, 5, 6, 4 |
| Row 8 | 1, 7, 5, 9, 2, 4, 6, 3 | Column 8 | 9, 3, 7, 8, 6 | Box 8 | 3, 9, 2, 5, 7 |
| Row 9 | 6, 4, 5, 7, 9 | Column 9 | 7, 2, 1, 6, 5, 3, 9 | Box 9 | 7, 5, 4, 6, 3, 9 |

The rows, the columns and the boxes each add up to 46 givens.

#### Screen 1: The board and the goal

**Board:**

```
31..5..9.
.6.4..2.7
5.7.9..3.
.3.1.5972
79...35.1
.51.7.386
.8.3..7.5
17592.463
64.5.7..9
```

**Start state:** nothing selected. Mode: Place.

**Marked:** r5c5.

**Text:**

> Welcome to Sudoku! This is the board. It has 81 small squares, called cells. Some cells hold a digit, and the rest are empty. Your goal is to fill every empty cell with a digit from 1 to 9. Tap the marked cell to select it.

**Do:** tap r5c5.

**Right result:** r5c5 is selected. Its row, column and box light up. Mode: Place.

**After the right tap:** "Good. Tapping a cell selects it. Next, the one rule that says which digit goes where."

**Wrong taps:**

- Another cell: "That is a different cell. Tap the marked cell in the middle of the board."
- A digit on the number pad: "First pick a cell. Tap the marked cell in the middle of the board."
- The mode switch: "That switch is for later. Tap the marked cell in the middle of the board."
- Fallback: "Tap the marked cell in the middle of the board."

**Author's note:** no digit is placed. r5c5 is empty and sits in the middle of the board. Row 5 holds 7, 9, 3, 5, 1. Column 5 holds 5, 9, 7, 2. Box 5 holds 1, 5, 3, 7.

#### Screen 2: Rows

**Board:**

```
31..5..9.
.6.4..2.7
5.7.9..3.
.3.1.5972
79...35.1
.51.7.386
.8.3..7.5
17592.463
64.5.7..9
```

**Start state:** nothing selected. Mode: Place.

**Marked:** row 8.

**Text:**

> A row is a line of 9 cells going across. When a puzzle is solved, every row holds each digit from 1 to 9 exactly once. The marked row has one empty cell. Tap it.

**Do:** tap r8c6.

**Right result:** r8c6 is selected. Row 8, column 6 and box 8 light up. Mode: Place.

**After the right tap:** "Yes. See the whole row light up? A row never holds the same digit twice."

**Wrong taps:**

- A cell in row 8 that holds a digit: "That cell already holds a digit. Tap the empty cell in the marked row."
- A cell outside row 8: "That cell is not in the marked row. Tap the empty cell in the marked row."
- A digit on the number pad: "First tap the empty cell in the marked row."
- The mode switch: "That switch is for later. Tap the empty cell in the marked row."
- Fallback: "Tap the empty cell in the marked row."

**Author's note:** row 8 holds 1, 7, 5, 9, 2, 4, 6, 3. Its only empty cell is r8c6. Column 6 holds 5, 3, 7 and box 8 holds 3, 9, 2, 5, 7, so the missing 8 clashes with nothing. Screen 6 places it.

#### Screen 3: Columns

**Board:**

```
31..5..9.
.6.4..2.7
5.7.9..3.
.3.1.5972
79...35.1
.51.7.386
.8.3..7.5
17592.463
64.5.7..9
```

**Start state:** nothing selected. Mode: Place.

**Marked:** column 2.

**Text:**

> A column is a line of 9 cells going down. Every column holds each digit from 1 to 9 exactly once, too. The marked column has one empty cell. Tap it.

**Do:** tap r3c2.

**Right result:** r3c2 is selected. Row 3, column 2 and box 1 light up. Mode: Place.

**After the right tap:** "Right. A column follows the same rule as a row."

**Wrong taps:**

- A cell in column 2 that holds a digit: "That cell already holds a digit. Tap the empty cell in the marked column."
- A cell outside column 2: "That cell is not in the marked column. Tap the empty cell in the marked column."
- A digit on the number pad: "First tap the empty cell in the marked column."
- The mode switch: "That switch is for later. Tap the empty cell in the marked column."
- Fallback: "Tap the empty cell in the marked column."

**Author's note:** column 2 holds 1, 6, 3, 9, 5, 8, 7, 4. Its only empty cell is r3c2, which is 2 in the solution. Row 3 holds 5, 7, 9, 3 and box 1 holds 3, 1, 6, 5, 7, so 2 clashes with nothing. Nothing is placed here.

#### Screen 4: Boxes

**Board:**

```
31..5..9.
.6.4..2.7
5.7.9..3.
.3.1.5972
79...35.1
.51.7.386
.8.3..7.5
17592.463
64.5.7..9
```

**Start state:** nothing selected. Mode: Place.

**Marked:** box 6.

**Text:**

> The thick lines split the board into 9 boxes. Each box is 3 cells wide and 3 cells tall. Every box holds each digit from 1 to 9 exactly once, too. The marked box has one empty cell. Tap it.

**Do:** tap r5c8.

**Right result:** r5c8 is selected. Row 5, column 8 and box 6 light up. Mode: Place.

**After the right tap:** "That is the whole rule of Sudoku: every row, column and box holds 1 to 9, once each."

**Wrong taps:**

- A cell in box 6 that holds a digit: "That cell already holds a digit. Tap the empty cell in the marked box."
- A cell outside box 6: "That cell is not in the marked box. Tap the empty cell in the marked box."
- A digit on the number pad: "First tap the empty cell in the marked box."
- The mode switch: "That switch is for later. Tap the empty cell in the marked box."
- Fallback: "Tap the empty cell in the marked box."

**Author's note:** box 6 (rows 4 to 6, columns 7 to 9) holds 9, 7, 2, 5, 1, 3, 8, 6. Its only empty cell is r5c8, which is 4 in the solution. Row 5 holds 7, 9, 3, 5, 1 and column 8 holds 9, 3, 7, 8, 6, so 4 clashes with nothing. Nothing is placed here.

#### Screen 5: Given digits stay put

**Board:**

```
31..5..9.
.6.4..2.7
5.7.9..3.
.3.1.5972
79...35.1
.51.7.386
.8.3..7.5
17592.463
64.5.7..9
```

**Start state:** nothing selected. Mode: Place.

**Marked:** r1c5 (a given 5).

**Text:**

> The digits on the board at the start are called given digits. They are locked, so they never change. The digits you place look different, and you can change those. The Erase button clears a digit you placed. Tap the marked 5.

**Do:** tap r1c5.

**Right result:** r1c5 is selected. Row 1, column 5 and box 2 light up, and so does every other cell that holds a 5 (GDD 2.3). Mode: Place.

**After the right tap:** "That 5 is a given digit, so it stays put. See how every other 5 lights up too? No row, column or box has two of them."

**Wrong taps:**

- Another cell holding 5 (r3c1, r4c6, r5c7, r6c2, r7c9, r8c3 or r9c4): "That is a given 5 too. For now, tap the marked one near the top."
- Any other cell: "Tap the marked 5 near the top of the board."
- A digit on the number pad: "Given digits never change. Tap the marked 5 to select it."
- The mode switch: "That switch is for later. Tap the marked 5."
- Fallback: "Tap the marked 5 near the top of the board."

**Author's note:** r1c5 is a given 5. The other given 5s are r3c1, r4c6, r5c7, r6c2, r7c9, r8c3 and r9c4. They lie in eight different rows (all but row 2), eight different columns (all but column 8) and eight different boxes (all but box 3), so the praise line is true. Selecting a cell that holds a digit highlights every other cell with that digit (GDD 2.2 and 2.3).

#### Screen 6: Place your first digit

**Board:**

```
31..5..9.
.6.4..2.7
5.7.9..3.
.3.1.5972
79...35.1
.51.7.386
.8.3..7.5
17592.463
64.5.7..9
```

**Start state:** r8c6 selected. Mode: Place. Ring of r8c6: all nine open. Placed: none.

**Marked:** row 8.

**Text:**

> Back to the row from before. We selected its empty cell for you. This row has every digit but one. Which digit is missing? Tap it on the number pad.

**Do:** tap 8 on the number pad.

**Technique:** `last_empty_cell`, row 8.

**Right result:** r8c6 holds 8 as a placed digit, and its ring hides. Row 8 is full.

**After the right tap:** "You placed your first digit! This row now holds 1 to 9, once each. That is how Sudoku works."

**Wrong taps:**

- 1, 2, 3, 4, 5, 6, 7 or 9: "This row already has a {d}, and a row holds each digit only once. Find the digit the row is missing."
- The selected cell: "This cell is ready. Tap the missing digit on the number pad."
- Another cell: "Keep this cell selected. Tap the missing digit on the number pad."
- The mode switch: "That switch is for later. Lesson 2 shows it. Tap the missing digit."
- Fallback: "Tap the digit this row is missing."

**Author's note:** row 8 holds 1 (r8c1), 7 (r8c2), 5 (r8c3), 9 (r8c4), 2 (r8c5), 4 (r8c7), 6 (r8c8) and 3 (r8c9). Only 8 is missing, so r8c6 is 8: the last empty cell of row 8. Column 6 holds 5, 3, 7 and box 8 holds 3, 9, 2, 5, 7, so 8 clashes with nothing. Every wrong digit message is true: each of 1 to 7 and 9 is in row 8. The solution has 8 in r8c6.

### 7.2 Lesson 2: The ring and Cross Out

**Teaches:** the candidate ring and Cross Out mode. Crossing a candidate by selecting the cell and tapping that digit on the number pad. A crossed candidate stays visible with an X. Tapping the same digit again restores it. Switching back to Place mode.

**Goal:** the player can cross out the digits a cell's row, column and box rule out, and bring back a digit crossed by mistake.

**Screens:** 8.

**Uses from earlier lessons:** rows, columns, boxes, and selecting a cell (lesson 1). Each screen repeats the rule for its group in one line, so a player who skipped lesson 1 can still follow.

#### The board

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

#### Screen 1: Meet the ring

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

#### Screen 2: Two modes

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

#### Screen 3: Cross out a digit

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

#### Screen 4: The X stays

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

#### Screen 5: The column

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

#### Screen 6: The box

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

#### Screen 7: Bring a digit back

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

**After the right tap:** "7 is back. In Cross Out mode, tap a crossed digit again to bring it back."

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

#### Screen 8: Back to Place mode

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

### 7.3 Lesson 3: Last empty cell

**Teaches:** the last empty cell. When a row, column or box has only one empty cell, only one digit is missing from it, and that digit goes in the empty cell. Spotting one without help, and seeing that each placed digit can open up the next one.

**Goal:** the player can spot a row, column or box with only one empty cell and fill in its missing digit.

**Screens:** 5.

**Uses from earlier lessons:** the rule, selecting a cell and placing a digit (lesson 1). No ring work.

**Mode:** Place on every screen.

#### The board

All five screens share this board. Each digit the player places stays on the board for the rest of the lesson, as the player's own digit.

```
314.52698
.6.43..57
5.7.9.1.4
.3.14..72
7.26.3..1
..1279.8.
28936...5
175.28.63
64.51.8.9
```

52 given digits. The board is fuller than in other lessons, so that rows, columns and boxes with one gap are easy to find.

**Which groups have exactly one empty cell, screen by screen.** This proves that screens 4 and 5, which have no marks, have exactly one right answer.

| Before screen | Placed so far | Groups with exactly one empty cell |
| --- | --- | --- |
| 1 | none | row 1 (r1c4), column 5 (r5c5), column 9 (r6c9), box 7 (r9c3) |
| 2 | r1c4 = 7 | column 5, column 9, box 7 |
| 3 | r1c4 = 7, r6c9 = 6 | column 5, box 7 |
| 4 | r1c4 = 7, r6c9 = 6, r9c3 = 3 | column 5 only |
| 5 | r1c4 = 7, r6c9 = 6, r9c3 = 3, r5c5 = 8 | box 5 only (r4c6) |

Empty cells per group before screen 4, counted by hand: rows 1 to 9 have 0, 4, 4, 4, 4, 3, 3, 2, 2. Columns 1 to 9 have 3, 3, 2, 2, 1, 5, 6, 4, 0. Boxes 1 to 9 have 3, 3, 2, 5, 2, 4, 0, 3, 4. Placing 8 at r5c5 on screen 4 takes row 5 from 4 to 3, column 5 from 1 to 0 and box 5 from 2 to 1, so before screen 5 box 5 is the only group with one empty cell.

**Solution.** The grid from the start of section 7. Every given digit above matches it, and so does every digit the player places.

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

**Legality check, done by hand.** Given digits in each group, with no repeats in any of them:

| Group | Givens | Group | Givens | Group | Givens |
| --- | --- | --- | --- | --- | --- |
| Row 1 | 3, 1, 4, 5, 2, 6, 9, 8 | Column 1 | 3, 5, 7, 2, 1, 6 | Box 1 | 3, 1, 4, 6, 5, 7 |
| Row 2 | 6, 4, 3, 5, 7 | Column 2 | 1, 6, 3, 8, 7, 4 | Box 2 | 5, 2, 4, 3, 9 |
| Row 3 | 5, 7, 9, 1, 4 | Column 3 | 4, 7, 2, 1, 9, 5 | Box 3 | 6, 9, 8, 5, 7, 1, 4 |
| Row 4 | 3, 1, 4, 7, 2 | Column 4 | 4, 1, 6, 2, 3, 5 | Box 4 | 3, 7, 2, 1 |
| Row 5 | 7, 2, 6, 3, 1 | Column 5 | 5, 3, 9, 4, 7, 6, 2, 1 | Box 5 | 1, 4, 6, 3, 2, 7, 9 |
| Row 6 | 1, 2, 7, 9, 8 | Column 6 | 2, 3, 9, 8 | Box 6 | 7, 2, 1, 8 |
| Row 7 | 2, 8, 9, 3, 6, 5 | Column 7 | 6, 1, 8 | Box 7 | 2, 8, 9, 1, 7, 5, 6, 4 |
| Row 8 | 1, 7, 5, 2, 8, 6, 3 | Column 8 | 9, 5, 7, 8, 6 | Box 8 | 3, 6, 2, 8, 5, 1 |
| Row 9 | 6, 4, 5, 1, 8, 9 | Column 9 | 8, 7, 4, 2, 1, 5, 3, 9 | Box 9 | 5, 6, 3, 8, 9 |

The rows, the columns and the boxes each add up to 52 givens.

#### Screen 1: A row with one empty cell

**Board:**

```
314.52698
.6.43..57
5.7.9.1.4
.3.14..72
7.26.3..1
..1279.8.
28936...5
175.28.63
64.51.8.9
```

**Start state:** nothing selected. Mode: Place. Placed: none.

**Marked:** row 1.

**Text:**

> When a row has only one empty cell, just one digit is missing from it. That digit must go in the empty cell. We call this the last empty cell. The marked row has one. Tap its empty cell, then tap the digit the row is missing.

**Do:** two taps in this order: tap r1c4, then tap 7 on the number pad.

**Technique:** `last_empty_cell`, row 1.

**Right result:** after the first tap, r1c4 is selected. After the second, r1c4 holds 7 as a placed digit and row 1 is full.

**After the right tap:** "Right. 7 was the only digit this row was missing."

**Wrong taps.** `{next}` is "Tap the empty cell in the marked row, then tap the missing digit." before r1c4 is selected, and "Now tap the digit this row is missing." once it is.

- 1, 2, 3, 4, 5, 6, 8 or 9: "This row already has a {d}. {next}"
- 7, before r1c4 is selected: "Pick the cell first. {next}"
- r1c4, once it is selected: "This cell is ready. {next}"
- A cell in row 1 that holds a digit: "That cell already holds a digit. {next}"
- A cell outside row 1: "That cell is not in the marked row. {next}"
- The mode switch: "Stay in Place mode. {next}"
- Fallback: "{next}"

**Author's note:** row 1 holds 3, 1, 4, 5, 2, 6, 9, 8, so it is missing only 7, and its only empty cell is r1c4. Column 4 holds 4, 1, 6, 2, 3, 5 and box 2 holds 5, 2, 4, 3, 9: no 7, so 7 clashes with nothing. Every wrong digit message is true, because each of the other eight digits is in row 1. The solution has 7 in r1c4.

#### Screen 2: A column with one empty cell

**Board:**

```
314.52698
.6.43..57
5.7.9.1.4
.3.14..72
7.26.3..1
..1279.8.
28936...5
175.28.63
64.51.8.9
```

**Start state:** nothing selected. Mode: Place. Placed: r1c4 = 7.

**Marked:** column 9.

**Text:**

> The same works for a column. The marked column has only one empty cell. Tap it, then tap the digit the column is missing.

**Do:** two taps in this order: tap r6c9, then tap 6 on the number pad.

**Technique:** `last_empty_cell`, column 9.

**Right result:** after the first tap, r6c9 is selected. After the second, r6c9 holds 6 as a placed digit and column 9 is full.

**After the right tap:** "Yes. 6 was the only digit missing from this column."

**Wrong taps.** `{next}` is "Tap the empty cell in the marked column, then tap the missing digit." before r6c9 is selected, and "Now tap the digit this column is missing." once it is.

- 1, 2, 3, 4, 5, 7, 8 or 9: "This column already has a {d}. {next}"
- 6, before r6c9 is selected: "Pick the cell first. {next}"
- r6c9, once it is selected: "This cell is ready. {next}"
- A cell in column 9 that holds a digit: "That cell already holds a digit. {next}"
- A cell outside column 9: "That cell is not in the marked column. {next}"
- The mode switch: "Stay in Place mode. {next}"
- Fallback: "{next}"

**Author's note:** column 9 holds 8, 7, 4, 2, 1, 5, 3, 9, so it is missing only 6, and its only empty cell is r6c9. Row 6 holds 1, 2, 7, 9, 8 and box 6 holds 7, 2, 1, 8: no 6. The 7 placed at r1c4 is not in row 6, column 9 or box 6. The solution has 6 in r6c9.

#### Screen 3: A box with one empty cell

**Board:**

```
314.52698
.6.43..57
5.7.9.1.4
.3.14..72
7.26.3..1
..1279.8.
28936...5
175.28.63
64.51.8.9
```

**Start state:** nothing selected. Mode: Place. Placed: r1c4 = 7, r6c9 = 6.

**Marked:** box 7.

**Text:**

> And the same works for a box. The marked box has only one empty cell. Tap it, then tap the digit the box is missing.

**Do:** two taps in this order: tap r9c3, then tap 3 on the number pad.

**Technique:** `last_empty_cell`, box 7.

**Right result:** after the first tap, r9c3 is selected. After the second, r9c3 holds 3 as a placed digit and box 7 is full.

**After the right tap:** "Well done. 3 was the only digit missing from this box."

**Wrong taps.** `{next}` is "Tap the empty cell in the marked box, then tap the missing digit." before r9c3 is selected, and "Now tap the digit this box is missing." once it is.

- 1, 2, 4, 5, 6, 7, 8 or 9: "This box already has a {d}. {next}"
- 3, before r9c3 is selected: "Pick the cell first. {next}"
- r9c3, once it is selected: "This cell is ready. {next}"
- A cell in box 7 that holds a digit: "That cell already holds a digit. {next}"
- A cell outside box 7: "That cell is not in the marked box. {next}"
- The mode switch: "Stay in Place mode. {next}"
- Fallback: "{next}"

**Author's note:** box 7 (rows 7 to 9, columns 1 to 3) holds 2, 8, 9, 1, 7, 5, 6, 4, so it is missing only 3, and its only empty cell is r9c3. Row 9 holds 6, 4, 5, 1, 8, 9 and column 3 holds 4, 7, 2, 1, 9, 5: no 3. The placed 7 (r1c4) and 6 (r6c9) are not in row 9, column 3 or box 7. The solution has 3 in r9c3.

#### Screen 4: Find one yourself

**Board:**

```
314.52698
.6.43..57
5.7.9.1.4
.3.14..72
7.26.3..1
..1279.8.
28936...5
175.28.63
64.51.8.9
```

**Start state:** nothing selected. Mode: Place. Placed: r1c4 = 7, r6c9 = 6, r9c3 = 3.

**Marked:** nothing.

**Text:**

> Now find one on your own. Somewhere on this board, one row, column or box has just one empty cell. Tap that cell, then tap the digit that is missing.

**Do:** two taps in this order: tap r5c5, then tap 8 on the number pad.

**Technique:** `last_empty_cell`, column 5.

**Right result:** after the first tap, r5c5 is selected. After the second, r5c5 holds 8 as a placed digit and column 5 is full.

**After the right tap:** "You found it! That column had just one empty cell, and 8 was missing."

**Wrong taps.** `{next}` is "Find the row, column or box with just one empty cell, and tap that cell." before r5c5 is selected, and "Now tap the one digit this column is missing." once it is.

- 1, 2, 3, 4, 5, 6, 7 or 9: "Not {d}. {next}"
- 8, before r5c5 is selected: "Pick the cell first. {next}"
- r5c5, once it is selected: "This cell is ready. {next}"
- Another empty cell: "Not that one. Its row, its column and its box each still have two or more empty cells. {next}"
- A cell that holds a digit: "That cell already holds a digit. {next}"
- The mode switch: "Stay in Place mode. {next}"
- Fallback: "{next}"

**Author's note:** column 5 holds 5, 3, 9, 4 (rows 1 to 4) and 7, 6, 2, 1 (rows 6 to 9), so it is missing only 8, and its only empty cell is r5c5. The count before screen 4 (see the board section) shows that column 5 is the only group with exactly one empty cell, so the answer is unique and the "Another empty cell" message is true for every other empty cell. Row 5 holds 7, 2, 6, 3, 1 and box 5 holds 1, 4, 6, 3, 2, 7, 9: no 8. The "Not {d}" message names no group, so it is true before and after the cell is selected. The solution has 8 in r5c5.

#### Screen 5: One digit leads to the next

**Board:**

```
314.52698
.6.43..57
5.7.9.1.4
.3.14..72
7.26.3..1
..1279.8.
28936...5
175.28.63
64.51.8.9
```

**Start state:** nothing selected. Mode: Place. Placed: r1c4 = 7, r6c9 = 6, r9c3 = 3, r5c5 = 8.

**Marked:** nothing.

**Text:**

> Each digit you place fills a gap in its row, its column and its box. The digit you just placed left one of them with a single empty cell. Find that cell, then fill it.

**Do:** two taps in this order: tap r4c6, then tap 5 on the number pad.

**Technique:** `last_empty_cell`, box 5.

**Right result:** after the first tap, r4c6 is selected. After the second, r4c6 holds 5 as a placed digit and box 5 is full.

**After the right tap:** "Great. One digit led to the next. Solving a Sudoku often goes just like that."

**Wrong taps.** `{next}` is "Find the row, column or box with just one empty cell, and tap that cell." before r4c6 is selected, and "Now tap the one digit this box is missing." once it is.

- 1, 2, 3, 4, 6, 7, 8 or 9: "Not {d}. {next}"
- 5, before r4c6 is selected: "Pick the cell first. {next}"
- r4c6, once it is selected: "This cell is ready. {next}"
- Another empty cell: "Not that one. Its row, its column and its box each still have two or more empty cells. {next}"
- A cell that holds a digit: "That cell already holds a digit. {next}"
- The mode switch: "Stay in Place mode. {next}"
- Fallback: "{next}"

**Author's note:** box 5 (rows 4 to 6, columns 4 to 6) holds the givens 1, 4, 6, 3, 2, 7, 9 and the 8 placed at r5c5 on screen 4. It is missing only 5, and its only empty cell is r4c6. The 8 at r5c5 is in box 5, so the text is true: the last digit placed left its box with a single empty cell. Before screen 5, box 5 is the only group with exactly one empty cell (see the board section), so the answer is unique. Row 4 holds 3, 1, 4, 7, 2 and column 6 holds 2, 3, 9, 8: no 5. The solution has 5 in r4c6.

### 7.4 Lesson 4: Hidden single

**Teaches:** the hidden single, found one digit at a time: take a box, row or column and a digit it still needs, see which empty cells that digit's copies rule out, and place the digit in the one cell left. In a box, a row and a column. Why the cell's ring can still show other digits. Tapping a digit on the board to light up all its copies.

**Goal:** the player can find the only cell in a row, column or box where a digit can go.

**Screens:** 6.

**Uses from earlier lessons:** the rule, selecting a cell and placing a digit (lesson 1). The ring and its crosses (lesson 2), on screen 2 only. The last empty cell (lesson 3) is not needed.

**Mode:** Place on every screen.

#### The board

All six screens share this board. Each digit the player places stays on the board for the rest of the lesson, as the player's own digit.

```
.1.7...9.
9...3...7
.....6..4
83...5.7.
7..6....1
..1..93..
2.9..4..5
17.9.8.6.
6.35..8..
```

31 given digits, so there are plenty of empty cells to rule out.

**The four placements.** In each, the digit fits in only one empty cell of the group, and that cell still has two or more digits open, so it is a hidden single and not a naked single.

| Screen | Cell and digit | Group | Copies that rule out the group's other empty cells | Digits still open in the cell |
| --- | --- | --- | --- | --- |
| 2 | r3c3 = 7 | box 1 | r1c4 and r2c9 (their rows), r5c1 and r8c2 (their columns) | 2, 5, 7, 8 |
| 3 | r7c5 = 6 | row 7 | r9c1 (box 7), r5c4 (column 4), r8c8 (box 9) | 1, 6, 7 |
| 4 | r5c6 = 3 | column 6 | r2c5 (box 2 and row 2), r9c3 (row 9) | 2, 3 |
| 6 | r8c3 = 5 | box 7 | r7c9 (row 7), r9c4 (row 9) | 4, 5 |

**Solution.** The grid from the start of section 7. Every given digit above matches it, and so does every digit the player places.

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

**Legality check, done by hand.** Given digits in each group, with no repeats in any of them:

| Group | Givens | Group | Givens | Group | Givens |
| --- | --- | --- | --- | --- | --- |
| Row 1 | 1, 7, 9 | Column 1 | 9, 8, 7, 2, 1, 6 | Box 1 | 1, 9 |
| Row 2 | 9, 3, 7 | Column 2 | 1, 3, 7 | Box 2 | 7, 3, 6 |
| Row 3 | 6, 4 | Column 3 | 1, 9, 3 | Box 3 | 9, 7, 4 |
| Row 4 | 8, 3, 5, 7 | Column 4 | 7, 6, 9, 5 | Box 4 | 8, 3, 7, 1 |
| Row 5 | 7, 6, 1 | Column 5 | 3 | Box 5 | 5, 6, 9 |
| Row 6 | 1, 9, 3 | Column 6 | 6, 5, 9, 4, 8 | Box 6 | 7, 1, 3 |
| Row 7 | 2, 9, 4, 5 | Column 7 | 3, 8 | Box 7 | 2, 9, 1, 7, 6, 3 |
| Row 8 | 1, 7, 9, 8, 6 | Column 8 | 9, 7, 6 | Box 8 | 4, 9, 8, 5 |
| Row 9 | 6, 3, 5, 8 | Column 9 | 7, 4, 1, 5 | Box 9 | 5, 6, 8 |

The rows, the columns and the boxes each add up to 31 givens.

#### Screen 1: One digit, one box

**Board:**

```
.1.7...9.
9...3...7
.....6..4
83...5.7.
7..6....1
..1..93..
2.9..4..5
17.9.8.6.
6.35..8..
```

**Start state:** nothing selected. Mode: Place. Placed: none.

**Marked:** box 1, and the 7s at r1c4, r2c9, r5c1 and r8c2.

**Text:**

> A hidden single is a digit that fits in only one cell of a row, column or box. Here is how to find one. The top left box needs a 7. Each marked 7 rules out its own row and its own column, so 7 cannot go there. Only one empty cell in the box is left. Tap it.

**Do:** tap r3c3.

**Right result:** r3c3 is selected. Its row, column and box light up. Its ring shows all nine digits. Mode: Place.

**After the right tap:** "Yes. In this box, 7 fits in only one cell. That is a hidden single."

**Wrong taps:**

- r1c1, r1c3, r2c2 or r2c3: "7 cannot go there. That row already has a 7. Find the empty cell in the box that no 7 rules out."
- r3c1 or r3c2: "7 cannot go there. That column already has a 7. Find the empty cell in the box that no 7 rules out."
- r1c2 or r2c1: "That cell already holds a digit. Find the empty cell in the box where 7 fits."
- A marked 7 (r1c4, r2c9, r5c1 or r8c2): "That is one of the 7s. It rules out its own row and column. Find the empty cell in the box where 7 still fits."
- Any other cell: "That cell is outside the top left box. Find the empty cell in that box where 7 fits."
- A digit on the number pad: "First find the cell. Tap the empty cell in the top left box where 7 fits."
- The mode switch: "Stay in Place mode. Tap the empty cell in the top left box where 7 fits."
- Fallback: "Tap the empty cell in the top left box where 7 fits."

**Author's note:** box 1 holds 1 (r1c2) and 9 (r2c1). Its empty cells are r1c1, r1c3, r2c2, r2c3, r3c1, r3c2 and r3c3. Row 1 holds a 7 at r1c4, which rules out r1c1 and r1c3. Row 2 holds a 7 at r2c9, which rules out r2c2 and r2c3. Column 1 holds a 7 at r5c1, which rules out r3c1. Column 2 holds a 7 at r8c2, which rules out r3c2. Row 3 holds 6, 4, column 3 holds 1, 9, 3 and box 1 holds 1, 9: no 7, so r3c3 is the one cell left. The solution has 7 in r3c3.

#### Screen 2: The ring cannot tell, the box can

**Board:**

```
.1.7...9.
9...3...7
.....6..4
83...5.7.
7..6....1
..1..93..
2.9..4..5
17.9.8.6.
6.35..8..
```

**Start state:** r3c3 selected. Mode: Place. Ring of r3c3: 1, 3, 4, 6 and 9 crossed; 2, 5, 7 and 8 open. The lesson sets these crosses at the start of this screen. Placed: none.

**Marked:** r3c3.

**Text:**

> We crossed out every digit this cell's row, column and box already have. 2, 5, 7 and 8 are still open, so the ring alone cannot tell which one goes here. But 7 has no other place in this box. So this cell must be 7. Tap 7.

**Do:** tap 7 on the number pad.

**Technique:** `hidden_single`, box 1, digit 7.

**Right result:** r3c3 holds 7 as a placed digit, and its ring hides.

**After the right tap:** "Well done. A hidden single can hide among other open digits, so look at one digit at a time."

**Wrong taps:**

- 2, 5 or 8: "{d} is still open, but that only means nothing rules it out yet. 7 has no other place in this box. Tap 7."
- 1, 3, 4, 6 or 9: "{d} has an X, because this cell's row, column or box already has a {d}. Tap 7."
- The selected cell: "This cell is ready. Tap 7 on the number pad."
- Another cell: "Keep this cell selected. Tap 7 on the number pad."
- The mode switch: "Stay in Place mode. Tap 7 on the number pad."
- Fallback: "Tap 7 on the number pad."

**Author's note:** row 3 holds 6 and 4. Column 3 holds 1, 9 and 3. Box 1 holds 1 and 9. So r3c3 has 1, 3, 4, 6 and 9 ruled out, and 2, 5, 7 and 8 open: four candidates, so it is not a naked single, and every cross the lesson sets is a ruled out digit. Screen 1 shows that 7 has no other empty cell in box 1, so this is a hidden single. (7 is also a hidden single in row 3: r3c1, r3c2, r3c4, r3c5, r3c7 and r3c8 are ruled out by the 7s at r5c1, r8c2, r1c4 and r2c9, and the 7 at r4c8 also rules out r3c8.) The solution has 7 in r3c3.

#### Screen 3: In a row

**Board:**

```
.1.7...9.
9...3...7
.....6..4
83...5.7.
7..6....1
..1..93..
2.9..4..5
17.9.8.6.
6.35..8..
```

**Start state:** nothing selected. Mode: Place. Placed: r3c3 = 7.

**Marked:** row 7, and the 6s at r5c4, r8c8 and r9c1.

**Text:**

> A hidden single works in a row too. The marked row needs a 6. Remember, a 6 rules out its own row, column and box. The marked 6s rule out every empty cell in this row but one. Tap that cell, then tap 6.

**Do:** two taps in this order: tap r7c5, then tap 6 on the number pad.

**Technique:** `hidden_single`, row 7, digit 6.

**Right result:** after the first tap, r7c5 is selected. After the second, r7c5 holds 6 as a placed digit.

**After the right tap:** "Right. In this row, 6 fits in only one cell."

**Wrong taps.** `{next}` is "Find the empty cell in the marked row where 6 fits, tap it, then tap 6." before r7c5 is selected, and "Now tap 6." once it is.

- r7c2, r7c7 or r7c8: "6 cannot go there. Its box already has a 6. {next}"
- r7c4: "6 cannot go there. Its column already has a 6. {next}"
- A marked 6 (r5c4, r8c8 or r9c1): "That is one of the 6s. It rules out cells in its own row, column and box. {next}"
- A cell in row 7 that holds a digit: "That cell already holds a digit. {next}"
- r7c5, once it is selected: "This cell is ready. {next}"
- Any other cell: "That cell is not in the marked row. {next}"
- 6, before r7c5 is selected: "Pick the cell first. {next}"
- Any other digit: "We are looking for 6 in this row. {next}"
- The mode switch: "Stay in Place mode. {next}"
- Fallback: "{next}"

**Author's note:** row 7 holds 2, 9, 4, 5. Its empty cells are r7c2, r7c4, r7c5, r7c7 and r7c8. The 6 at r9c1 rules out r7c2 (box 7). The 6 at r5c4 rules out r7c4 (column 4). The 6 at r8c8 rules out r7c7 and r7c8 (box 9). Column 5 holds 3 and box 8 holds 4, 9, 8, 5: no 6, so r7c5 is the one cell left. Row 7, column 5 and box 8 rule out 2, 3, 4, 5, 8 and 9 in r7c5, which leaves 1, 6 and 7 open: not a naked single. The placed 7 at r3c3 does not touch row 7, column 5 or box 8. (6 is also a hidden single in box 8, whose other empty cells r7c4, r8c5, r9c5 and r9c6 are ruled out by the 6s at r5c4, r8c8 and r9c1.) The solution has 6 in r7c5.

#### Screen 4: In a column

**Board:**

```
.1.7...9.
9...3...7
.....6..4
83...5.7.
7..6....1
..1..93..
2.9..4..5
17.9.8.6.
6.35..8..
```

**Start state:** nothing selected. Mode: Place. Placed: r3c3 = 7, r7c5 = 6.

**Marked:** column 6.

**Text:**

> And in a column. The marked column needs a 3. Look for the 3s on the board. They rule out every empty cell in this column but one. Tap that cell, then tap 3.

**Do:** two taps in this order: tap r5c6, then tap 3 on the number pad.

**Technique:** `hidden_single`, column 6, digit 3.

**Right result:** after the first tap, r5c6 is selected. After the second, r5c6 holds 3 as a placed digit.

**After the right tap:** "Yes. In this column, 3 fits in only one cell."

**Wrong taps.** `{next}` is "Find the empty cell in the marked column where 3 fits, tap it, then tap 3." before r5c6 is selected, and "Now tap 3." once it is.

- r1c6: "3 cannot go there. Its box already has a 3. {next}"
- r2c6 or r9c6: "3 cannot go there. Its row already has a 3. {next}"
- A cell in column 6 that holds a digit: "That cell already holds a digit. {next}"
- r5c6, once it is selected: "This cell is ready. {next}"
- Any other cell: "That cell is not in the marked column. {next}"
- 3, before r5c6 is selected: "Pick the cell first. {next}"
- Any other digit: "We are looking for 3 in this column. {next}"
- The mode switch: "Stay in Place mode. {next}"
- Fallback: "{next}"

**Author's note:** column 6 holds 6, 5, 9, 4, 8. Its empty cells are r1c6, r2c6, r5c6 and r9c6. The 3 at r2c5 rules out r1c6 (box 2) and r2c6 (row 2, and box 2). The 3 at r9c3 rules out r9c6 (row 9). Row 5 holds 7, 6, 1 and box 5 holds 5, 6, 9: no 3, so r5c6 is the one cell left. Row 5, column 6 and box 5 rule out 1, 4, 5, 6, 7, 8 and 9 in r5c6, which leaves 2 and 3 open: not a naked single. The placed 7 (r3c3) and 6 (r7c5) are not peers of r5c6. (3 is also a hidden single in row 5 and in box 5, through the 3s at r2c5, r4c2, r6c7 and r9c3.) The solution has 3 in r5c6.

#### Screen 5: Light up a digit

**Board:**

```
.1.7...9.
9...3...7
.....6..4
83...5.7.
7..6....1
..1..93..
2.9..4..5
17.9.8.6.
6.35..8..
```

**Start state:** nothing selected. Mode: Place. Placed: r3c3 = 7, r7c5 = 6, r5c6 = 3.

**Marked:** r4c6 (a given 5).

**Text:**

> Here is a tip. Tap a digit on the board, and every copy of that digit lights up. Then you can see at a glance which rows, columns and boxes already have it. Tap the marked 5.

**Do:** tap r4c6.

**Right result:** r4c6 is selected. Its row, column and box light up, and so do the other 5s, at r7c9 and r9c4 (GDD 2.3). Mode: Place.

**After the right tap:** "See all the 5s light up? Use this trick whenever you hunt for a hidden single."

**Wrong taps:**

- r7c9 or r9c4: "That is a 5 too, and it would work the same way. For now, tap the marked 5."
- Any other cell: "Tap the marked 5 in the middle of the board."
- A digit on the number pad: "Tap the 5 on the board itself, not on the number pad."
- The mode switch: "Stay in Place mode. Tap the marked 5."
- Fallback: "Tap the marked 5 in the middle of the board."

**Author's note:** no digit is placed. The board holds three 5s, all given: r4c6, r7c9 and r9c4. Selecting a cell that holds a digit highlights every other cell with that digit (GDD 2.2 and 2.3), and screen 6 starts with these 5s still lit.

#### Screen 6: Your turn

**Board:**

```
.1.7...9.
9...3...7
.....6..4
83...5.7.
7..6....1
..1..93..
2.9..4..5
17.9.8.6.
6.35..8..
```

**Start state:** r4c6 selected, so the 5s are lit. Mode: Place. Placed: r3c3 = 7, r7c5 = 6, r5c6 = 3.

**Marked:** nothing.

**Text:**

> Your turn. Look at the 5s. One box has only one empty cell left where 5 can go. Find that cell, tap it, then tap 5.

**Do:** two taps in this order: tap r8c3, then tap 5 on the number pad.

**Technique:** `hidden_single`, box 7, digit 5.

**Right result:** after the first tap, r8c3 is selected. After the second, r8c3 holds 5 as a placed digit.

**After the right tap:** "You found a hidden single on your own. With this and the last empty cell, you can solve every Beginner puzzle."

**Wrong taps.** `{next}` is "Find the box where 5 fits in just one empty cell, tap that cell, then tap 5." before r8c3 is selected, and "Now tap 5." once it is.

- r7c2 or r9c2: "Right box! But that cell's row already has a 5. {next}"
- A 5 on the board (r4c6, r7c9 or r9c4): "That is one of the 5s. Each 5 rules out its own row, column and box. {next}"
- r8c3, once it is selected: "This cell is ready. {next}"
- Any other cell that holds a digit: "That cell already holds a digit. {next}"
- Any other empty cell: "Not that one. That cell's box already has a 5, or it has more than one spot for 5. {next}"
- 5, before r8c3 is selected: "Pick the cell first. {next}"
- Any other digit: "We are looking for 5. {next}"
- The mode switch: "Stay in Place mode. {next}"
- Fallback: "{next}"

**Author's note:** box 7 holds 2, 9, 1, 7, 6, 3. Its empty cells are r7c2, r8c3 and r9c2. The 5 at r7c9 rules out r7c2 (row 7). The 5 at r9c4 rules out r9c2 (row 9). Row 8 holds 1, 7, 9, 8, 6 and column 3 holds 7 (placed), 1, 9, 3: no 5, so r8c3 is the one cell left. Row 8, column 3 and box 7 rule out 1, 2, 3, 6, 7, 8 and 9 in r8c3, which leaves 4 and 5 open: not a naked single.

The answer is unique. Boxes 5, 8 and 9 already hold a 5. Places for 5 in the other boxes: box 1 has six (r1c1, r1c3, r2c2, r2c3, r3c1, r3c2), box 2 has two (r1c5, r3c5), box 3 has five (r1c7, r2c7, r2c8, r3c7, r3c8), box 4 has four (r5c2, r5c3, r6c1, r6c2), box 6 has three (r5c7, r5c8, r6c8), and box 7 has one (r8c3). Checked by rows and columns too: the only row or column where 5 has a single place is row 8, and that place is r8c3 again. So the "Any other empty cell" message is true for every other empty cell. The solution has 5 in r8c3.

### 7.5 Lesson 5: Naked single

**Teaches:** the naked single: a cell whose row, column and box rule out every digit but one. The player finds it with the ring: cross out what the row holds, then the column, then the box, see one digit left, switch to Place mode and place it.

**Goal:** the player can cross out a cell's ring until one digit is left, then place that digit.

**Screens:** 6.

**Uses from earlier lessons:** the rule (lesson 1). The ring, Cross Out mode, the X that stays, and switching modes (lesson 2). The hidden single, only as a comparison on screen 1 (lesson 4).

**Mode:** Place on screens 1 and 2 until the switch, Cross Out on screens 3 to 5, back to Place on screen 6.

#### The board

All six screens share this board. Only the ring of r4c7, the selection and the mode change, until r4c7 is filled on screen 6.

```
.1.7..6.8
9...3.25.
5.7..6...
83...5...
7..6...41
4.1.7...6
..93..7.5
1.5..8.6.
.4..1.82.
```

34 given digits. The target cell is r4c7.

**Why r4c7 is a naked single:**

- Row 4 holds 8 (r4c1), 3 (r4c2) and 5 (r4c6). Nothing else.
- Column 7 holds 6 (r1c7), 2 (r2c7), 7 (r7c7) and 8 (r9c7). Nothing else.
- Box 6 holds 4 (r5c8), 1 (r5c9) and 6 (r6c9). Nothing else.
- Screen 3 crosses the row's 3, 5 and 8. Screen 4 crosses the column's 2, 6 and 7; its 8 is crossed already. Screen 5 crosses the box's 1 and 4; its 6 is crossed already.
- Ruled out: 1, 2, 3, 4, 5, 6, 7 and 8. Only 9 is left.

**Why it is not a hidden single or a last empty cell:** the board has only two 9s, r2c1 and r7c3. In row 4, 9 still fits in r4c4, r4c5, r4c8 and r4c9 as well (only r4c3 is ruled out, by r7c3). In column 7, 9 still fits in r3c7, r5c7, r6c7 and r8c7. In box 6, 9 still fits in r4c8, r4c9, r5c7, r6c7 and r6c8. Row 4 has six empty cells, column 7 five, box 6 six. So only the naked single proves r4c7 = 9, which is what this lesson teaches.

**Solution.** The grid from the start of section 7. Every given digit above matches it.

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

**Legality check, done by hand.** Given digits in each group, with no repeats in any of them:

| Group | Givens | Group | Givens | Group | Givens |
| --- | --- | --- | --- | --- | --- |
| Row 1 | 1, 7, 6, 8 | Column 1 | 9, 5, 8, 7, 4, 1 | Box 1 | 1, 9, 5, 7 |
| Row 2 | 9, 3, 2, 5 | Column 2 | 1, 3, 4 | Box 2 | 7, 3, 6 |
| Row 3 | 5, 7, 6 | Column 3 | 7, 1, 9, 5 | Box 3 | 6, 8, 2, 5 |
| Row 4 | 8, 3, 5 | Column 4 | 7, 6, 3 | Box 4 | 8, 3, 7, 4, 1 |
| Row 5 | 7, 6, 4, 1 | Column 5 | 3, 7, 1 | Box 5 | 5, 6, 7 |
| Row 6 | 4, 1, 7, 6 | Column 6 | 6, 5, 8 | Box 6 | 4, 1, 6 |
| Row 7 | 9, 3, 7, 5 | Column 7 | 6, 2, 7, 8 | Box 7 | 9, 1, 5, 4 |
| Row 8 | 1, 5, 8, 6 | Column 8 | 5, 4, 6, 2 | Box 8 | 3, 8, 1 |
| Row 9 | 4, 1, 8, 2 | Column 9 | 8, 1, 6, 5 | Box 9 | 7, 5, 6, 8, 2 |

The rows, the columns and the boxes each add up to 34 givens.

#### Screen 1: One digit left

**Board:**

```
.1.7..6.8
9...3.25.
5.7..6...
83...5...
7..6...41
4.1.7...6
..93..7.5
1.5..8.6.
.4..1.82.
```

**Start state:** nothing selected. Mode: Place. Ring of r4c7: all nine open.

**Marked:** r4c7.

**Text:**

> In lesson 4, a digit had only one cell left. Now it is the other way round: a cell has only one digit left, because its row, column and box rule out all the others. That is called a naked single: the last digit sits alone in the ring, plain to see. Tap the marked cell.

**Do:** tap r4c7.

**Right result:** r4c7 is selected. Its row, column and box light up. The ring is unchanged. Mode: Place.

**After the right tap:** "Good. Let's find out which digit this cell can be."

**Wrong taps:**

- Another cell: "That is a different cell. Tap the marked cell."
- A digit on the number pad: "First pick a cell. Tap the marked cell."
- The mode switch: "We will use that next. First, tap the marked cell."
- Fallback: "Tap the marked cell."

**Author's note:** row 4 holds 8, 3, 5. Column 7 holds 6, 2, 7, 8. Box 6 holds 4, 1, 6. Together they rule out every digit but 9 in r4c7. Nothing is crossed or placed yet.

#### Screen 2: Cross Out mode

**Board:**

```
.1.7..6.8
9...3.25.
5.7..6...
83...5...
7..6...41
4.1.7...6
..93..7.5
1.5..8.6.
.4..1.82.
```

**Start state:** r4c7 selected. Mode: Place. Ring of r4c7: all nine open.

**Marked:** the mode switch.

**Text:**

> To mark the ring, you need Cross Out mode. Tap the mode switch.

**Do:** tap the mode switch.

**Right result:** mode is Cross Out. r4c7 stays selected. The ring is unchanged.

**After the right tap:** "Good. You are in Cross Out mode."

**Wrong taps:**

- A digit on the number pad: "In Place mode, that would put a big digit in the cell. Tap the mode switch first."
- The selected cell: "This cell is ready. Now tap the mode switch."
- Another cell: "Keep this cell selected. Tap the mode switch."
- Fallback: "Tap the mode switch to choose Cross Out."

**Author's note:** row 4 holds 8, 3, 5. Column 7 holds 6, 2, 7, 8. Box 6 holds 4, 1, 6. The lesson asks the player to prove the digit with the ring before placing it, so a digit tap in Place mode is a wrong tap here, even 9.

#### Screen 3: The row

**Board:**

```
.1.7..6.8
9...3.25.
5.7..6...
83...5...
7..6...41
4.1.7...6
..93..7.5
1.5..8.6.
.4..1.82.
```

**Start state:** r4c7 selected. Mode: Cross Out. Ring of r4c7: all nine open.

**Marked:** r4c1 (the 8), r4c2 (the 3) and r4c6 (the 5).

**Text:**

> First the row. A row holds each digit only once, so this cell cannot be any digit the row already has. Cross out each of them. The marked cells show where they are.

**Do:** tap 3, 5 and 8 on the number pad, in any order. Each X appears at once, and the screen waits for the rest.

**Right result:** ring of r4c7: 3, 5 and 8 crossed. 1, 2, 4, 6, 7 and 9 open.

**After the right tap:** "Good. 3, 5 and 8 are crossed out."

**Wrong taps.** `{next}` is "Cross out each digit this row has." at every stage.

- 2, 6 or 7: "Yes, this column has a {d}. We get to the column next. {next}"
- 1 or 4: "Yes, this box has a {d}. We get to the box soon. {next}"
- 9: "There is no 9 in this row, column or box. Keep 9 open. {next}"
- 3, 5 or 8 once it has an X: "{d} already has an X. Tapping it again would bring it back. {next}"
- The selected cell: "The small digits are too small to tap. Use the number pad. {next}"
- Another cell: "Keep this cell selected. Use the number pad. {next}"
- The mode switch: "Stay in Cross Out mode for now. {next}"
- Fallback: "{next}"

**Author's note:** row 4 holds 8 (r4c1), 3 (r4c2) and 5 (r4c6), so 3, 5 and 8 are ruled out by the row. Each wrong tap message is true: 2, 6 and 7 are in column 7 (6 is also in box 6); 1 and 4 are only in box 6; 9 is in none of the three groups.

#### Screen 4: The column

**Board:**

```
.1.7..6.8
9...3.25.
5.7..6...
83...5...
7..6...41
4.1.7...6
..93..7.5
1.5..8.6.
.4..1.82.
```

**Start state:** r4c7 selected. Mode: Cross Out. Ring of r4c7: 3, 5 and 8 crossed. 1, 2, 4, 6, 7 and 9 open.

**Marked:** r1c7 (the 6), r2c7 (the 2), r7c7 (the 7) and r9c7 (the 8).

**Text:**

> Now the column. Cross out each digit this column has that is still open in the ring.

**Do:** tap 2, 6 and 7 on the number pad, in any order. Each X appears at once, and the screen waits for the rest.

**Right result:** ring of r4c7: 2, 3, 5, 6, 7 and 8 crossed. 1, 4 and 9 open.

**After the right tap:** "Nice. The column has an 8 too, and 8 already had its X from the row."

**Wrong taps.** `{next}` is "Cross out each digit this column has that is still open." at every stage.

- 8: "This column has an 8 too, but 8 already has an X. Tapping it again would bring it back. {next}"
- 3 or 5, or 2, 6 or 7 once it has an X: "{d} already has an X. Tapping it again would bring it back. {next}"
- 1 or 4: "Yes, this box has a {d}. We get to the box next. {next}"
- 9: "There is no 9 in this row, column or box. Keep 9 open. {next}"
- The selected cell: "The small digits are too small to tap. Use the number pad. {next}"
- Another cell: "Keep this cell selected. Use the number pad. {next}"
- The mode switch: "Stay in Cross Out mode for now. {next}"
- Fallback: "{next}"

**Author's note:** column 7 holds 6 (r1c7), 2 (r2c7), 7 (r7c7) and 8 (r9c7). 8 was crossed on screen 3 for the row, so the new crosses are 2, 6 and 7. Row 4 holds 8, 3, 5. Box 6 holds 4, 1, 6. Each wrong tap message is true: 1 and 4 are only in box 6, and 9 is in none of the groups.

#### Screen 5: The box

**Board:**

```
.1.7..6.8
9...3.25.
5.7..6...
83...5...
7..6...41
4.1.7...6
..93..7.5
1.5..8.6.
.4..1.82.
```

**Start state:** r4c7 selected. Mode: Cross Out. Ring of r4c7: 2, 3, 5, 6, 7 and 8 crossed. 1, 4 and 9 open.

**Marked:** r5c8 (the 4), r5c9 (the 1) and r6c9 (the 6).

**Text:**

> Last, the box. Cross out each digit this box has that is still open in the ring.

**Do:** tap 1 and 4 on the number pad, in either order. After the first of the two, its X appears and the screen waits for the other.

**Right result:** ring of r4c7: 1, 2, 3, 4, 5, 6, 7 and 8 crossed. Only 9 open.

**After the right tap:** "Look: only 9 is still open. Every other digit is ruled out. This cell is a naked single."

**Wrong taps.** `{next}` is "Cross out each digit this box has that is still open." at every stage.

- 6: "This box has a 6 too, but 6 already has an X. Tapping it again would bring it back. {next}"
- 2, 3, 5, 7 or 8, or 1 or 4 once it has an X: "{d} already has an X. Tapping it again would bring it back. {next}"
- 9: "There is no 9 in this row, column or box. Keep 9 open. {next}"
- The selected cell: "The small digits are too small to tap. Use the number pad. {next}"
- Another cell: "Keep this cell selected. Use the number pad. {next}"
- The mode switch: "Stay in Cross Out mode for now. {next}"
- Fallback: "{next}"

**Author's note:** box 6 (rows 4 to 6, columns 7 to 9) holds 4 (r5c8), 1 (r5c9) and 6 (r6c9). Its other cells (r4c7, r4c8, r4c9, r5c7, r6c7, r6c8) are empty. 6 was crossed on screen 4 for the column, so the new crosses are 1 and 4. Row 4 holds 8, 3, 5 and column 7 holds 6, 2, 7, 8. All three groups together rule out 1 to 8, which leaves 9, so the praise line is true.

#### Screen 6: Place it

**Board:**

```
.1.7..6.8
9...3.25.
5.7..6...
83...5...
7..6...41
4.1.7...6
..93..7.5
1.5..8.6.
.4..1.82.
```

**Start state:** r4c7 selected. Mode: Cross Out. Ring of r4c7: 1 to 8 crossed, 9 open.

**Marked:** the mode switch.

**Text:**

> When only one digit is left, that digit goes in the cell. Switch back to Place mode, then place the one digit still open in the ring.

**Do:** two taps in this order: tap the mode switch, then tap 9 on the number pad.

**Technique:** `naked_single`, r4c7, digit 9.

**Right result:** after the first tap, the mode is Place and r4c7 stays selected. After the second, r4c7 holds 9 as a placed digit, and its ring hides.

**After the right tap:** "You solved a naked single! Now you know every step you need for Easy puzzles."

**Wrong taps.** `{next}` is "Switch to Place mode, then place the one digit still open." before the switch, and "Now place the one digit still open." after it.

- 9, before the switch: "In Cross Out mode, that would cross out 9. Switch to Place mode first."
- 1, 2, 3, 4, 5, 6, 7 or 8: "{d} has an X, so this cell cannot be {d}. {next}"
- The mode switch, after the switch: "Stay in Place mode. {next}"
- The selected cell: "This cell is ready. {next}"
- Another cell: "Keep this cell selected. {next}"
- Fallback: "{next}"

**Author's note:** row 4 holds 8, 3, 5. Column 7 holds 6, 2, 7, 8. Box 6 holds 4, 1, 6. So r4c7 has every digit but 9 ruled out: a naked single. As the board section shows, 9 is not a hidden single in row 4, column 7 or box 6, so the naked single is what proves it. The "{d} has an X" message is true at both stages, because 1 to 8 are all crossed. The solution has 9 in r4c7.

## 8. Decisions on lesson behavior

These shape how every lesson behaves. The Development Manager settled items 1 to 9 on 2026-10-11. Items 10 to 13 come from writing lessons 1, 3, 4 and 5 in Phase 2, and each one fits the lesson data format in docs/ARCHITECTURE.md section 10 as written.

1. **Auto Cross is always off in a lesson,** whatever the setting says (GDD 15.4). Lesson 2 could not work otherwise, because Auto Cross would cross 2, 3, 4, 6 and 9 before the player does.
2. **Every tap that is not the step's answer is a wrong tap,** including selecting a different cell. A wrong tap changes nothing: not the board, the ring, the selection or the mode. It shows the screen's explanation, and the player tries again. Lessons are scripted around one cell, so every tap teaches something. GDD 15.4 and AT-63 say the same.
3. **After the right answer,** a praise line and a Next button appear. The screen does not move on by itself. Once a screen's answer is complete and the praise line and Next show, every other tap on the board, the pad and the controls is ignored, with no text, until the player taps Next (GDD 15.4, ARCHITECTURE.md section 10).
4. **No timer, score or hints in a lesson** (GDD 15.4 and 10.4). A tap on Erase or Undo that is not the step's answer gets the screen's fallback text.
5. **Every lesson is open from the start.** Leaving a lesson part way through means it starts again at screen 1 next time. A lesson counts as finished when the player completes the answer of its last step (GDD 15.4), even if they leave before tapping the last Next.
6. **Bart's example as five given digits.** In lesson 2 the 3 is one cell shared by the row and the box, and the 4 is one cell shared by the column and the box. GDD 4.4 (Position B) uses seven given digits, with separate cells for those. Both rule out the same five digits and leave 1, 5, 7 and 8 open.
7. **Lesson 1 overlaps lesson 3 a little.** Lesson 1's last screen fills a row with one empty cell. That is accepted: lesson 3 turns it into a technique.
8. **The lesson validity test checks for at least one solution,** not exactly one. Lesson boards are legal and can be completed, but they are not puzzles with a single solution. ARCHITECTURE.md section 10 says the same. Every board in this file completes to the grid at the start of section 7, which goes in each lesson file as its `solution`.
9. **The lesson data format** is ARCHITECTURE.md section 10. Lessons 1 to 5 use: a start board; a start selection or none; a start mode; digits placed on earlier screens (`placed`); digits already crossed in a cell's ring (`crossed`); marked cells (a marked row, column or box is its nine cells) and marked controls; a goal of one tap, several taps in any order, or a few taps in a fixed order (`sequence`); the technique of each placement; the praise line; wrong tap texts by digit, by cell and by control, with `{d}` and `{next}`; and a fallback text.
10. **Placed digits stay for the rest of the lesson.** A digit the player places stays on the board, as the player's own digit, on the later screens of the same lesson. Lessons 3 and 4 build on this, and lesson 3 screen 5 depends on it. Erase and Undo stay wrong taps, so a placed digit cannot be removed during a lesson. Leaving the lesson clears them, because it starts again at screen 1 (item 5).
11. **Some screens ask for taps in a fixed order:** tap a cell, then place a digit (lessons 3 and 4), or switch modes, then place a digit (lesson 5 screen 6). The praise line shows after the last tap. A tap that belongs to a later part of the answer is a wrong tap until its turn, for example tapping the right digit before the right cell is selected.
12. **Wrong tap texts hold at every stage of a screen.** The format has one wrong tap list per screen, and a match cannot tell whether the first tap of the answer is done yet. So each wrong tap text in this file is true both before and after that tap, and the part that changes goes in `{next}`. Where a text can only fire at one stage, the screen says so ("before r1c4 is selected", "once it is selected").
13. **Every screen that places a digit names its technique,** as `last_empty_cell`, `hidden_single` or `naked_single`, so the lesson data test can check that `NextStep.placements_by` finds that cell and digit on the board as it stands, placed digits included. Lesson 4's targets each keep two or more open digits, so they are hidden singles and not naked singles. Lesson 5's target is a naked single and not a hidden single in any of its groups.
