# Team ranking of the three directions

Phase 1 team review for Hard Stop 1 (BRIEF section 12). Each reviewer ranks Gridline, Pebble and Pop, best first, with short reasons. The Development Manager combines the rankings into one recommendation for Bart.

Write-ups: [Gridline](direction-gridline.md), [Pebble](direction-pebble.md), [Pop](direction-pop.md). Ring layouts: [ring-layouts.md](ring-layouts.md).

## Senior graphic designer

2026-10-11. Judged readability first, then fun, then polish, on the 15 screenshots, the state sheets and the ring close-ups at 720 and 1080 px.

1. **Pop.**
   - The best balance of readability and fun: a calm white board with pure ink candidates (36 unit font, almost Gridline's size) inside the loudest, most game-like frame.
   - Keys meet the 48 dp touch target (about 54 by 66 dp on a 360 dp phone), and time, score and Hint sit together right under the board.
   - It is the one Bart would recognize from across the room. Risks to fix in Phase 2: the big Hint block sits next to the mode tabs, where a stray tap costs points, and a full lemon page may tire the eye over a long session.
2. **Gridline.**
   - The most readable board: the largest candidates (37 unit font), the strongest contrast between box and cell lines, and the cheapest to draw.
   - Calm and timeless, with a clear identity from the poster band.
   - But its single row of nine keys is 36 dp wide per key, below the 48 dp target, and it is the plainest, closer to a tool than a game.
3. **Pebble.**
   - The friendliest and most original, with the biggest keys; a natural fit for lessons and beginners.
   - But it has the smallest candidates (layout B's font sits exactly on our 9 dp floor at 360 dp) because the gutters and tile gaps take board space.
   - And it costs two to three times as much to redraw (20 to 31 ms against 7 to 11 ms on this laptop), a real risk for 60 fps on a mid-range phone.

## Lead game designer

2026-10-11. Judged play first: reading the board over a 30 to 45 minute puzzle, how clear the mode is, the risk of costly mistaps, then whether each screen carries the GDD content.

1. **Gridline.**
   - Best board for a long puzzle: the largest candidates, calm white cells, the strongest box lines, and the clearest hand X inside the selected cell.
   - Safest place for Hint: at the top, away from the board and the pad. The mode shows on the bar, on every key and on the cell frame.
   - Weak spot: the keys are 36 dp wide. With conflicts-only checking, a slip onto the next digit that clashes with nothing stays hidden. Phase 2 must widen the keys or prove the single row works on Bart's phone.
2. **Pop.**
   - Readable board with pure ink candidates, and the clearest pad: big keys, an obvious Cross Out look on the tabs and keys, and Undo and Erase within reach.
   - The big Hint block sits about 14 dp under row 9, one of the most tapped areas. A hint is charged the moment it is tapped and is never refunded.
   - The full lemon page is the most tiring over 45 minutes, and the magenta X is softer on the pink selected cell.
3. **Pebble.**
   - Biggest keys and the friendliest lessons, but the smallest candidates (9.0 dp at 360 dp).
   - The yellow selected tile is the hardest place to read a crossed candidate, and that is the cell the player is working on. The conflict and same digit pinks are almost the same color.
   - Thinnest mode cue on the board (a 3 unit dotted frame), and the Hint pill sits about 6 dp from Pause.

## Development Manager

2026-10-11. Judged by the brief's order: readability first, then fun, then polish, with the 48 dp touch target from brief section 3 as a hard line.

1. **Pop.**
   - A calm, readable lines-style board with strong box lines, nearly as large as Gridline's candidates.
   - The only direction that is both readable and meets the 48 dp touch target without changing its layout.
   - The freshest and most fun, the least like a template. Its main risk, Hint right under the board, is a placement fix, not a change of identity.
2. **Gridline.**
   - The most readable board and the cheapest to draw.
   - Its signature single row of nine keys is 36 dp wide; meeting 48 dp would change the layout that defines it.
   - The plainest of the three.
3. **Pebble.**
   - The friendliest, with the best keypad.
   - The smallest candidates and two to three times the redraw cost, and readability is the top bar.

## Combined recommendation

Scoring 3 points for a first place, 2 for a second and 1 for a third: Pop 8, Gridline 7, Pebble 3. All three reviewers put Pebble last.

**Recommendation: Pop**, with these Phase 2 fixes as conditions:

- Move Hint well clear of the board, the pad and Pause, so a stray tap never buys a hint.
- Put a clear gap between the digit keys and Undo and Erase.
- Tone down the lemon page enough for a 45 minute session, and check the magenta X on the pink selected cell.
- The cross-direction fixes from the lead game designer's review (selected cell plus hint target, the mode cue on the board, the Auto Cross slash on 7, the hint panel and disabled states, the "Best time" label), which apply whichever direction wins.

**Close alternative: Gridline**, if Bart prefers the calmest, most readable board. It needs its keypad reworked to meet 48 dp.
