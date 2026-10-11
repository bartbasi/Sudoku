# Puzzle generation timing

Owner: puzzle-engine-dev. Phase 2, 2026-10-11. For Bart's decision at Hard Stop 2: generate puzzles on the phone, ship a pre-built bank, or a mix.

## Recommendation

A mix: generate on the phone for Beginner, Easy, Medium and Hard, and ship a small pre-built bank for Expert only.

- Beginner to Hard: estimated typical wait on a mid-range phone well under a second, 9 in 10 under 2 seconds, worst seen about 4 seconds (Hard). A short "making your puzzle" moment is enough.
- Expert: estimated typical wait about 5 seconds on a mid-range phone (mean 6), 1 in 10 over 13 seconds, and about 1 start in 100 near half a minute. That is too long to ask on every Expert start, and a slower phone makes it worse.
- An Expert bank of 1,000 puzzles is about 82 KB as plain text (41 KB packed), takes about 25 minutes to build on this laptop, and keeps puzzle IDs working exactly as they do now (see "If a bank is shipped").

## Results on Windows

Machine: this Windows 11 laptop, Intel Core i7-10750H (6 cores, 12 threads, 2.6 GHz base, up to 5.0 GHz on one core), Godot 4.7.2 editor binary run headless (a debug build), one thread.

Each level generated a fixed list of seeds (1 and up). Only the `PuzzleGenerator.generate` call is timed. Every puzzle was then checked outside the timer: exactly one solution (backtracking solver), the stored solution, and graded at its level by the technique solver. All 1,600 passed. The 90th percentile is the nearest rank. The whole run took 231 seconds.

| Level | Puzzles | Mean ms | Median ms | 90th pct ms | Worst ms | Attempts per puzzle | Hit rate per attempt | Mean givens |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Beginner | 500 of 500 | 13 | 11 | 16 | 53 | 1.00 | 100.0% | 24.9 |
| Easy | 500 of 500 | 24 | 20 | 46 | 104 | 2.17 | 46.0% | 24.5 |
| Medium | 300 of 300 | 55 | 41 | 110 | 344 | 3.30 | 30.3% | 24.5 |
| Hard | 200 of 200 | 187 | 122 | 434 | 1045 | 7.29 | 13.7% | 24.7 |
| Expert | 100 of 100 | 1518 | 1161 | 3231 | 4927 | 57.66 | 1.7% | 24.9 |

The hardest technique each level's puzzles needed:

| Level | Hardest technique |
| --- | --- |
| Beginner | hidden single 100% |
| Easy | naked single 100% |
| Medium | pointing 54%, naked pair 29%, claiming 18% |
| Hard | Y-Wing 59%, hidden pair 30%, X-Wing 6%, naked triple 5%, hidden triple 1% |
| Expert | XYZ-Wing 84%, Swordfish 16% |

Repeat it with:

```
timeout 3000 godot --headless --path . --script res://tools/puzzles/measure_generation.gd
```

## How the generator reaches each level

One attempt fills a random full grid, then tries to remove every digit once in a random order. A removal stays if the technique solver can still finish the board using only the techniques of the target level and below. A board the techniques can finish has exactly one solution, so no separate uniqueness check is needed while removing. The result is graded with all 13 techniques in the GDD's fixed order and kept if it grades exactly at the target level. The backtracking solver then confirms one solution as a second check. If the attempt grades lower, the next attempt starts from a new grid, drawn from the same seeded random sequence, so a seed always ends at the same puzzle.

The hit rate is the share of attempts that land exactly on the level. Removing digits while only Hard techniques are allowed (or Expert ones) rarely creates a board that truly needs them: a Hard attempt hits 1 time in 7, an Expert attempt 1 time in 58. An attempt costs about 25 ms here, so the hit rate decides the time.

What I tried for Hard and Expert, measured on the same seeds:

- Removing in stages (first with Beginner techniques only, then Easy, and so on up to the target) halved the hit rate at every level. Dropped.
- After a miss, putting 8 to 16 removed digits back and removing again on the same grid: no better than a new grid once the solver was fast (1.6 to 2.1 s per Expert puzzle against 1.5 s, 60 seeds each). Dropped, to keep the code simple.
- A faster yes or no check for each removal (singles placed in bulk instead of one step per restart, with the same techniques) and sharing work between techniques: about 1.2 times faster per attempt. Kept.

## Estimating phone times

Multiplier: **4 times this laptop**, for a mid-range Android phone running GDScript. A plausible range is 3 to 6 times. These are estimates; nothing was run on a phone.

Why 4:

- Raw speed of one core. Generation runs on one thread. A mid-range phone from the last few years (Cortex-A78 class big cores at about 2.2 to 2.6 GHz, for example a Galaxy A54 or A55, or a Snapdragon 7 series phone) scores roughly 1.3 to 1.6 times lower than this laptop's i7-10750H in single core benchmarks such as Geekbench 6.
- GDScript is an interpreter. Its inner loop is all branches, table lookups and short jumps, which phone cores with smaller caches and simpler branch prediction handle relatively worse than a benchmark mix. That roughly doubles the gap again.
- Little cores. The game should generate on a worker thread so the screen stays responsive. Android may run a background thread on a little core (Cortex-A55), which is 2 to 3 times slower than a big core. This is why the range goes up to 6.
- In the other direction, an exported release build skips some debug checks the editor binary does, so the phone gets back perhaps 10 to 20 percent.

A low end phone with only little cores could be 10 times slower or more. Phase 5 already checks the Expert wait on Bart's phone; that will confirm or correct the multiplier.

## Estimated times on a mid-range phone

Desktop times from the table above, times 4. The last column puts the worst case at the 3 to 6 times range.

| Level | Mean | Median | 90th pct | Worst seen | Worst seen at 3x to 6x |
| --- | --- | --- | --- | --- | --- |
| Beginner | 0.05 s | 0.04 s | 0.06 s | 0.2 s | 0.16 to 0.32 s |
| Easy | 0.1 s | 0.08 s | 0.2 s | 0.4 s | 0.3 to 0.6 s |
| Medium | 0.2 s | 0.16 s | 0.4 s | 1.4 s | 1.0 to 2.1 s |
| Hard | 0.7 s | 0.5 s | 1.7 s | 4.2 s | 3.1 to 6.3 s |
| Expert | 6.1 s | 4.6 s | 12.9 s | 19.7 s | 14.8 to 29.6 s |

The worst seen is from a limited sample. Each attempt is an independent try, so the tail can be estimated from the hit rate:

- Hard (13.7% per attempt, about 26 ms each): 1 start in 100 needs more than 31 attempts, about 0.8 s here and 3 s on the phone. 1 in 1,000: about 5 s on the phone.
- Expert (1.7% per attempt, about 26 ms each): 1 start in 100 needs more than 270 attempts, about 7 s here and 28 s on the phone. 1 in 1,000: about 42 s on the phone.

## The options

| Option | Waits | Cost |
| --- | --- | --- |
| Generate on the phone, every level | Beginner to Hard short. Expert about 5 s typical, sometimes half a minute or more. | Nothing extra to build. |
| Pre-built bank, every level | None. | A bank tool, a data file for every level, a loader with full validation (security review), and a finite set that repeats after N puzzles per level. |
| Mix: phone for Beginner to Hard, bank for Expert (recommended) | None noticeable. | A bank tool and one small data file, loaded and validated the same way. |

## If a bank is shipped

- The bank stores what `PuzzleGenerator.generate(4, seed)` returns for seeds 1 to N, one line per seed: the 81 givens as digits, 0 for an empty cell. The solution is not stored; the backtracking solver finds it in a few milliseconds.
- So an Expert puzzle keeps its normal ID, "1.4.<seed>". Saves, hints and bug reports work unchanged. The game picks Expert seeds from 1 to N and reads the givens from the bank instead of generating. A test checks a sample of bank lines against the generator, and a line that fails validation can be regenerated from its ID instead of crashing.
- Size: 82 bytes a puzzle as text, so 1,000 Expert puzzles are about 82 KB (41 KB if packed at 4 bits a cell). The APK compresses it further.
- Building 1,000 takes about 25 minutes on this laptop on one core.
- 1,000 is a suggestion: one Expert puzzle a day would take almost three years to repeat.

## Notes for Bart

- Expert puzzles mostly need an XYZ-Wing (84%); Swordfish shows up in 16%. Hard is mostly Y-Wing and hidden pair. That follows from how often each pattern arises, not from a choice in the code.
- Every level averages about 25 givens, Beginner included, because grading ignores the number of givens (GDD 11.1). A Beginner board looks as empty as an Expert one but only needs hidden singles. If you want easier levels to look gentler, the generator could stop removing at a minimum number of givens per level. That would be a GDD change; I have not done it.
- Puzzles have no symmetric pattern of givens. Symmetry is possible but lowers the hit rates.
- Suggestion, not built: instead of a bank, the game could generate the next Expert puzzle on a worker thread in the background while the player plays, so only the very first Expert start would wait. The generator is already safe on a worker thread (tested).
