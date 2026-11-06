# Sudoku: Google Play listing

Everything to paste into Play Console for Sudoku, and the answers to its App content questions. Bart does all Play Console work himself. Google's limits and the character counts are given for each text. The graphics are in docs/store/graphics/ (see the end of this file).

## Store listing (Grow > Store presence > Main store listing)

**App name** (30 characters at most): 28 characters

> Sudoku: Cross Out Candidates

Chosen by the DM on 2026-11-06 under Bart's go ahead for the Play upload. The name under the icon on the phone stays "Sudoku". A plain "Sudoku" would also be accepted by Play, but hundreds of apps use it, so the second half says what makes this one different.

**Short description** (80 characters at most): 76 characters

> Every empty cell shows its candidates. Cross them out by hand. Free, no ads.

**Full description** (4,000 characters at most): about 2,480 characters

<!-- full description start -->
A calm, classic 9 by 9 Sudoku with one big difference: every empty cell shows all nine candidates around its edge. You never have to write pencil marks. As you rule a digit out, you cross it out by hand, and it stays visible under its X, so you can always see what you already ruled out. Change your mind and tap it again to bring it back.

HOW IT PLAYS
Pick a cell, then tap a digit. In Place mode the digit goes in the cell. In Cross Out mode it crosses that candidate in the ring. Undo takes back any step, and erasing a digit brings back every mark exactly as you left it. Mistakes are shown as conflicts only, so the game never tells you the answer.

FIVE LEVELS
Beginner, Easy, Medium, Hard and Expert. Every puzzle has exactly one solution and can be solved by logic alone. Puzzles are made on your phone, so they never run out, and Expert puzzles come from a large set built into the game.

HINTS THAT TEACH
A hint never fills anything in. It points to a wrong digit, or it shows the next logical step and explains why, highlighting the candidate to cross out. Each hint costs a fifth of the puzzle's points, so you decide how much help is worth it.

LESSONS
Five short lessons teach the basics: how Sudoku works, the candidate ring and Cross Out, the last empty cell, the hidden single and the naked single. Each one lets you try the idea on a real board.

SCORE AND STATS
Each level has its own points. Finish faster for a time bonus. Stats keep, for every level, the puzzles you started and finished, your best and average times and your best score, and the game tells you when you beat a best.

YOUR WAY
- Light and dark looks
- Auto Cross, off by default, crosses candidates for you as you place digits
- Show candidates can hide the rings if you prefer a plain board
- Your puzzle is saved as you play; close the app and pick up where you left off
- Plays in portrait and works well on foldables and in split screen

FREE AND PRIVATE
Sudoku is free. There are no ads, no purchases, no accounts and no tracking. It works fully offline, asks for no permissions and collects no data. Everything it saves stays on your phone. Every picture and sound in the game is made by its own code.

Sudoku is open source, free software under the GNU GPL version 3 with additional terms, made by Play, Inc. The code is at github.com/bartbasi/Sudoku. If you would like to support more games like it, there is a quiet Buy me a coffee button, never expected and always appreciated.
<!-- full description end -->

**Category**: Game > Puzzle.

**Tags** (pick up to 5 from Play's list): Puzzle, Logic, Casual, Offline, Single player.

**Contact details**:

- Email (required, shown publicly): bartbasi@gmail.com
- Website: https://bartbasi.github.io/Sudoku/
- Phone: leave empty.

**Privacy policy URL**: https://bartbasi.github.io/Sudoku/privacy/ (published from the gh-pages branch).

## App content (Policy > App content)

- **Privacy policy**: the URL above.
- **Ads**: No, the app contains no ads.
- **App access**: All functionality is available without special access (no login).
- **Data safety**: "Does your app collect or share any of the required user data types?" **No.** Encryption in transit: not applicable, nothing is sent. Account creation: none. Data deletion: not applicable, nothing is collected. The listing then shows "No data collected" and "No data shared". Buy me a coffee only hands a fixed address to the phone's browser; the app itself sends nothing, so the answer stays No.
- **Content rating** (IARC questionnaire): category Game, a puzzle game. Answer No to violence, blood, fear, sexuality, nudity, language, controlled substances, crude humor, gambling and simulated gambling, users interacting or chatting, sharing user content, sharing the user's location, and digital purchases (there is nothing to buy; hints are paid from the puzzle's score). Expect Everyone, PEGI 3 or the local equivalent.
- **Target audience and content**: 13 and over, the same choice as WoodLogic and SumUp. Including ages under 13 brings in Google's Families policy, which is strict about links that take a child out of the app to a payment page, such as the Buy me a coffee button. The game is still rated for everyone.
- **News app**: No.
- **Government app**: No.
- **Financial features**: None.
- **Health**: None.

## Known risk: the Buy me a coffee button

Google Play's payments policy only allows in-app donation links to tax-exempt charities in some cases. Bart chose to show the button (2026-10-17 and 2026-10-22), as in his other games. Review could flag it. If review rejects the app for it, the button would have to be hidden in the Play build and the bundle uploaded again with a higher version code. That is a code change for Bart to approve first.

## Graphics

All made by the game's own code with `tools/build/store_graphics.gd` (see docs/release.md), in docs/store/graphics/. All but the icon are committed. The icon is made again on each run and not committed, because the app icon is never committed as an image (CLAUDE.md):

| File | Play Console field | Size |
| --- | --- | --- |
| `icon_512.png` | App icon | 512 by 512, 32-bit PNG |
| `feature_1024x500.png` | Feature graphic | 1024 by 500, no transparency |
| `phone_1_play.png` | Phone screenshot 1: a Medium puzzle in play, with hand crosses | 1080 by 1920 |
| `phone_2_hint.png` | Phone screenshot 2: a hint showing the next step | 1080 by 1920 |
| `phone_3_lesson.png` | Phone screenshot 3: lesson 2, the ring and Cross Out | 1080 by 1920 |
| `phone_4_dark.png` | Phone screenshot 4: a Hard puzzle in the dark look | 1080 by 1920 |
| `phone_5_completion.png` | Phone screenshot 5: the completion screen | 1080 by 1920 |
| `phone_6_stats.png` | Phone screenshot 6: stats | 1080 by 1920 |

The screenshots are 9:16, inside Play's rules (each side 320 to 3840 px, the long side at most twice the short side). The puzzles are made fresh on each run, so the boards change each time the tool runs.

## Countries

Production > Countries/regions: add all, or just the ones you want.

## Not in the listing

The listing names no other game or app. The rules are described in Sudoku's own words.
