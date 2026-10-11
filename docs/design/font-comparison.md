# Font comparison

Owner: senior-graphic-designer. For Hard Stop 1, 2026-10-11. Bart decides.

BRIEF section 8 leaves the font open: a font file, even a free one, is not "made in code", so the default is Godot's built-in font or the device's own font, and digit legibility at candidate size decides. Bart decided on 2026-10-11 to see the team's top-ranked direction both ways. That is Pop (see [ranking.md](ranking.md)).

## The two fonts

**Godot's built-in default font.** Open Sans SemiBold, compiled into the Godot engine. It is not a file in our repo and adds nothing to the app, and it looks the same on every phone. It comes in one weight; the lighter and heavier weights the directions use are made from it in code with Godot's embolden setting, so they are approximations rather than designed weights.

**Inter 4.1.** A free font by Rasmus Andersson, under the SIL Open Font License 1.1, made for screens and small sizes. It has real designed weights (Pop uses SemiBold, and Bold made a little heavier for its display type). The comparison turns on Inter's tabular figures, so every digit has the same width and timers do not jitter; in Inter that also gives the 1 a foot. The files sit only in `build/font_compare/`, which git and Godot both ignore.

**Why not the phone's own font.** On a Pixel the Android system font is Roboto, but many makers replace it (Samsung, Xiaomi and others ship their own) and players can change it, so "the device font" is a different font on different phones. It cannot be previewed faithfully here either. Windows has no Roboto: tested on this laptop, Godot asked for Roboto finds nothing and falls back to its own built-in font, and asked for the system sans-serif it draws Arial. Fetching Roboto to fake it would mean downloading a third-party file, which our rules forbid. It would also undercut two things we rely on: the ring layouts fit candidates to the measured shapes of the font in use, and the contrast and size checks hold only for the font they were run against. So the real choice is between the two fonts below.

## Side by side

Each Inter image has the same name as its default-font twin, with `-inter` before `.png`. Open the pair next to each other.

Screens, 1080 by 2400, ring layout A:

| Screen | Godot default font | Inter |
| --- | --- | --- |
| Play, light | [pop-play.png](pop-play.png) | [pop-play-inter.png](pop-play-inter.png) |
| Play, dark | [pop-play-dark.png](pop-play-dark.png) | [pop-play-dark-inter.png](pop-play-dark-inter.png) |
| Lesson step | [pop-lesson.png](pop-lesson.png) | [pop-lesson-inter.png](pop-lesson-inter.png) |
| Stats | [pop-stats.png](pop-stats.png) | [pop-stats-inter.png](pop-stats-inter.png) |
| Puzzle complete | [pop-complete.png](pop-complete.png) | [pop-complete-inter.png](pop-complete-inter.png) |

Ring close-ups, Pop light and dark, at true size on a 720 px wide phone (the smallest we support), and the same enlarged 3 times. The two images of a pair are the same size, so they line up:

| Layout | Godot default font | Inter |
| --- | --- | --- |
| A. Reading rows | [ring-rows-pop-small.png](ring-rows-pop-small.png), [x3](ring-rows-pop-small-x3.png) | [ring-rows-pop-small-inter.png](ring-rows-pop-small-inter.png), [x3](ring-rows-pop-small-x3-inter.png) |
| B. Clockwise | [ring-clockwise-pop-small.png](ring-clockwise-pop-small.png), [x3](ring-clockwise-pop-small-x3.png) | [ring-clockwise-pop-small-inter.png](ring-clockwise-pop-small-inter.png), [x3](ring-clockwise-pop-small-x3-inter.png) |
| C. Clockwise wide | [ring-clockwise-wide-pop-small.png](ring-clockwise-wide-pop-small.png), [x3](ring-clockwise-wide-pop-small-x3.png) | [ring-clockwise-wide-pop-small-inter.png](ring-clockwise-wide-pop-small-inter.png), [x3](ring-clockwise-wide-pop-small-x3-inter.png) |

Candidate sizes on that phone: layouts A and C draw candidates at 24.0 px in the default font and 23.3 px in Inter, because Inter's digits are a little wider; layout B at 18.7 px in both. Digit height is within one pixel either way.

## Digit legibility at candidate size

Judged on the 720 px close-ups, the brief's deciding test.

- **1.** The default font's 1 is a bare stem with a small flag. It reads, but it is the thinnest digit on the board, and under the Auto Cross slash it forms a small x shape. Inter's tabular 1 has a flag and a foot, so it stays a 1 next to the X marks and under the slash. This is Inter's one clear gain.
- **4.** Both are closed 4s with an open counter and read the same.
- **7.** Both are plain 7s and read the same.
- **9.** The default 9 has a curved tail, Inter's a straighter one. Both stay distinct from 8 and 6.
- **Crossed digits under the X.** With the digit drawn on top of the X and its 1 px knockout, every crossed digit can be named in both fonts, light and dark, in all three layouts. In layout B, the smallest, Inter's slightly sturdier strokes hold up a touch better next to the X tips; the difference is small.
- **The Auto Cross slash on 7.** The rising slash runs almost along the 7's own diagonal stroke, so in both fonts an auto-crossed 7 looks like a heavier gray 7 more than a crossed one. That comes from the mark, not the font, and neither font fixes it. Phase 2 should try a falling slash (top left to bottom right), which crosses the diagonals of 2, 4 and 7 instead of following them.
- **Everything else.** Both fonts carry Pop's heavy condensed capitals, the timer and the lesson text without anything cut off. Inter looks a little crisper and more even at display sizes, because its weights are designed; the default's emboldened weights are a little softer. It is a matter of taste, not legibility.

## Recommendation

Keep Godot's built-in font. On the smallest phone both fonts keep every candidate readable, crossed ones included, and Inter's only clear advantage is a footed 1, which is too small a gain to justify the project's first exception to "made in code". The default ships nothing and looks the same on every phone.

## What each choice costs

| | Godot default font | Inter |
| --- | --- | --- |
| Files in the app | None. It is inside the engine. | Two font files of about 420 KB each (SemiBold and Bold), about 840 KB, or the 880 KB variable font. |
| Rules | Fits "every visual is made in code" as it stands. | Bart must approve an exception to "no font files", and CLAUDE.md and ASSETS.md change to record it. |
| License | Nothing extra. | The SIL Open Font License asks that its copyright and license text travel with the font, so the app needs a credits or licenses screen, or the license file shipped beside the font. |
| Same on every phone | Yes. | Yes. |
| Weights | One weight; the others are made in code by emboldening, a little soft at large sizes. | Real designed weights. |
| Work in Phase 2 | None. | Import the files, point the Theme and the board at them, rerun every capture and the contrast and size checks with Inter. |
