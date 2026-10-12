# Sudoku: Architecture

Owner: Development Manager. Status: Phase 3, 2026-10-12, updated for Bart's Hard Stop 2 answers. Every area builds against this contract in Phase 3. If you need it changed, ask the Development Manager; never change another area's code to fit.

Read with docs/GDD.md (the rules), docs/DESIGN_SYSTEM.md (the look, and the skin token table), docs/LESSONS.md (lesson content) and CLAUDE.md (ownership and standing rules).

## 1. Shape of the game

```
           ui (App autoload, screens, save)            lessons (player, list)
                 |            \                            /       |
                 |             board (PlayArea: BoardView, NumberPad, BoardController)
                 |            /         |                          |
              design (Theme, Icons, Motion)   skins (GameSkin, Skins autoload, BoardPainter)
                 |                              |
                 +----------- core (rules, no Nodes) -------------+
                                    |
                               puzzles (solvers, generator; uses core Hint only)
              audio (Audio autoload): called by board and ui, depends on nothing
```

Dependency rules:

- core depends on nothing in src/.
- puzzles depends only on core (`Board`, `Hint` and `Sudoku`, from Phase 3).
- skins depends on core (read only: `Board` mark values, `GameSession.Mode`).
- design depends on skins (`GameSkin`).
- board depends on core, skins, design and audio.
- lessons depends on core, puzzles (tests only), board and design.
- ui depends on everything above. Nothing depends on ui except through the `App` autoload's public API (section 11).
- audio depends on nothing.

## 2. Conventions

- Godot 4.7.2, GDScript, statically typed. Untyped declarations are compile errors.
- Every public class has a `class_name`. Never reuse a Godot class name: the skin class is `GameSkin` because Godot already has `Skin`.
- core and puzzles classes extend `RefCounted`, never touch Nodes, the SceneTree, files or singletons, and hold no shared mutable state. They are safe to call from a worker thread.
- Cells are indexed 0 to 80 in code: `cell = row * 9 + col`, rows and columns 0 to 8, top left is 0. Boxes are 0 to 8 in reading order. Docs and lesson data use the GDD's 1-based `rXcY` names; only the lesson loader converts them.
- Digits are 1 to 9. 0 means empty.
- A grid is a `PackedInt32Array` of 81 ints, 0 to 9.
- Candidate marks are a `PackedByteArray` of 729 bytes, `index = cell * 9 + digit - 1`.
- Levels are ints: 0 Beginner, 1 Easy, 2 Medium, 3 Hard, 4 Expert (`Levels` constants).
- Technique ids are StringNames from GDD 11.3: `last_empty_cell`, `hidden_single`, `naked_single`, `pointing`, `claiming`, `naked_pair`, `hidden_pair`, `naked_triple`, `hidden_triple`, `x_wing`, `y_wing`, `swordfish`, `xyz_wing`, plus `wrong_digit` and `fallback` for hints.
- Signals use past tense or `_pressed` names and always list typed arguments, as below.
- Data that goes to disk uses `to_dict() -> Dictionary` and `static func from_dict(data: Variant) -> <Class>` that validates every field (section 12).
- Units: one canvas unit is one dp on every device. Every size in DESIGN_SYSTEM.md (dp) is used as written, and fonts are sized in the same units. `ScreenMetrics.apply_dp_scale` sets this up at startup and on every window resize (section 8). Nothing else scales the UI.

## 3. Autoloads

Registered in project.godot by the Development Manager, in this order:

| Name | Script | Owner | Purpose |
| --- | --- | --- | --- |
| `Skins` | res://src/skins/skin_service.gd | grid-cell-artist | Current skin and the list of built-in skins |
| `Audio` | res://src/audio/audio_service.gd | audio-dev | The click |
| `App` | res://src/ui/app.gd | ui-systems-dev | Settings, stats, lesson progress, the puzzle in progress, saving, navigation, Android lifecycle |

No other autoloads. core and puzzles never reference an autoload.

## 4. core (src/core, core-logic-dev)

### Sudoku (static helpers)

```gdscript
class_name Sudoku extends RefCounted
const CELLS := 81
static func row(cell: int) -> int
static func col(cell: int) -> int
static func box(cell: int) -> int
static func cell_at(row: int, col: int) -> int
static func peers(cell: int) -> PackedInt32Array          # the 20 peers, ascending, cached
static func group_cells(group: int) -> PackedInt32Array   # 0 to 8 boxes, 9 to 17 rows, 18 to 26 columns: the GDD 11.1 search order
static func is_grid(grid: PackedInt32Array) -> bool       # 81 values, each 0 to 9
static func is_complete_solution(grid: PackedInt32Array) -> bool
```

### Levels and Scoring

```gdscript
class_name Levels extends RefCounted
const BEGINNER := 0
const EASY := 1
const MEDIUM := 2
const HARD := 3
const EXPERT := 4
const COUNT := 5
static func name_of(level: int) -> String                # "Beginner" ... "Expert"
static func is_valid(level: int) -> bool

class_name Scoring extends RefCounted                     # GDD 9 and 10.3
static func points(level: int) -> int                     # 100, 200, 400, 700, 1000
static func par_seconds(level: int) -> int                # 480, 720, 1200, 1800, 2700
static func hint_cost(level: int) -> int                  # points / 5
static func live_score(level: int, hints_bought: int) -> int
static func time_bonus(level: int, seconds: int) -> int
static func final_score(level: int, hints_bought: int, seconds: int) -> int
```

### Board

```gdscript
class_name Board extends RefCounted
enum Mark { OPEN = 0, CROSSED_HAND = 1, RESTORED_HAND = 2, CROSSED_AUTO = 3 }
var givens: PackedInt32Array      # 81, 0 where not given
var digits: PackedInt32Array      # 81, givens and placed digits, 0 where empty
var marks: PackedByteArray        # 729, Mark values; kept for every non-given cell, also under a placed digit
static func create(givens: PackedInt32Array) -> Board
func is_given(cell: int) -> bool
func digit(cell: int) -> int
func mark(cell: int, digit: int) -> int
func is_crossed(cell: int, digit: int) -> bool            # CROSSED_HAND or CROSSED_AUTO
func is_ruled_out(cell: int, digit: int) -> bool          # a peer holds digit (GDD Terms)
func conflict_cells() -> PackedInt32Array                 # every cell, givens included, that clashes (GDD 6.1)
func is_conflict(cell: int) -> bool
func is_full() -> bool
func is_solved() -> bool                                  # full and no conflict
func duplicate_board() -> Board
func to_dict() -> Dictionary
static func from_dict(data: Variant) -> Board             # null if invalid
```

`Board` has no rules about undo or Auto Cross. Only `GameSession` changes a board during play; lessons may set up a starting position directly (section 10).

### Hint (data only)

```gdscript
class_name Hint extends RefCounted
var technique: StringName
var technique_name: String          # shown to the player, for example "Hidden single"
var text: String                    # one or two sentences, GDD 10.2
var lesson_title: String            # "Lesson: Hidden single", or "" when none
var targets: PackedInt32Array       # cells
var reasons: PackedInt32Array       # cells
var placement_cell: int = -1        # for a placement step
var placement_digit: int = 0
var eliminations: PackedInt32Array  # mark indices (cell * 9 + digit - 1) the step crosses
func to_dict() -> Dictionary
static func from_dict(data: Variant) -> Hint
```

### UndoStep and ActionResult

```gdscript
class_name UndoStep extends RefCounted
enum Kind { PLACE, REPLACE, ERASE, CROSS, RESTORE }
var kind: int
var cell: int
var old_digit: int
var new_digit: int
var mark_changes: PackedInt32Array  # triples: mark index, old Mark, new Mark (player and Auto Cross changes)
func to_dict() -> Dictionary
static func from_dict(data: Variant) -> UndoStep

class_name ActionResult extends RefCounted
var applied: bool = false           # false means "nothing happens" (GDD Terms)
var click: bool = false             # true for place, replace, cross, restore (GDD 3.4)
var changed_cells: PackedInt32Array
var completed: bool = false
var full_board_conflict: bool = false
var hint_closed: bool = false

class_name CompletionResult extends RefCounted   # what the completion screen shows (GDD 12)
var level: int
var seconds: int
var points_after_hints: int
var time_bonus: int
var final_score: int
var hints_used: int
var new_best: int                                # Stats.NEW_BEST_* bits
```

### GameSession

The whole state of one puzzle or one lesson board, and every rule that changes it: GDD sections 2 to 10 and 12.

```gdscript
class_name GameSession extends RefCounted
enum Mode { PLACE = 0, CROSS_OUT = 1 }

signal board_changed(cells: PackedInt32Array)
signal selection_changed(cell: int)
signal mode_changed(mode: int)
signal score_changed(score: int)
signal hint_changed(hint: Hint)              # null when the hint closes
signal undo_available_changed(available: bool)
signal full_board_conflict()
signal completed(final_seconds: int, final_score: int)

var puzzle_id: String                         # "" for a lesson
var level: int                                # -1 for a lesson (no score, no hints)
var solution: PackedInt32Array                # empty for a lesson
var board: Board
var mode: int
var selected: int                             # -1 when no cell is selected
var auto_cross: bool
var elapsed: float                            # seconds
var hints_bought: int
var hint: Hint                                # null when none on screen
var is_completed: bool

static func create(puzzle_id: String, level: int, givens: PackedInt32Array, solution: PackedInt32Array, auto_cross: bool) -> GameSession
static func for_lesson(board: Board, mode: int, selected: int) -> GameSession   # Auto Cross off, no score, no hints

func select(cell: int) -> void
func set_mode(mode: int) -> void
func toggle_mode() -> void
func press_digit(digit: int) -> ActionResult  # Place or Cross Out per mode (GDD 3.2)
func erase() -> ActionResult
func undo() -> ActionResult
func can_undo() -> bool
func set_auto_cross(on: bool) -> void         # GDD 5; not an undo step
func add_time(seconds: float) -> void         # ignored after completion
func elapsed_seconds() -> int
func score() -> int                           # live score, GDD 9.2
func hint_cost() -> int
func can_buy_hint() -> bool                   # GDD 10.4
func buy_hint(new_hint: Hint) -> bool         # charges and shows it; false if not allowed
func close_hint() -> void
func time_bonus() -> int                      # after completion
func final_score() -> int                     # after completion
func peer_cells() -> PackedInt32Array         # of the selected cell
func same_digit_cells() -> PackedInt32Array   # GDD 2.3, empty unless the selected cell holds a digit
func to_dict() -> Dictionary                  # everything in GDD 14, including undo history and the hint on screen
static func from_dict(data: Variant) -> GameSession   # null if anything is invalid
```

Signal order: an action that changes the board emits `board_changed` first, then `completed` or `full_board_conflict`. `set_auto_cross` emits `board_changed` with every cell whose marks it changed, so the board redraws at once (GDD 5.1). `hints_bought` stays between 0 and 5, so the score can never go below zero.

Rules the session owns, all from the GDD: Place, replace, erase, cross and restore; taps that do nothing; Auto Cross rules 1 to 3 including rings under placed digits; undo steps that include Auto Cross changes, and Auto Cross running again after an undo; conflicts; completion the moment a placement leaves a full board with no conflict; the full board message; the hint closing on place, replace, erase and undo; score never below zero. The session never reads the solution except to store it for hints.

### Settings, Stats, LessonProgress

```gdscript
class_name Settings extends RefCounted
var sound: bool = true
var skin_id: StringName = &"pop_light"
var auto_cross: bool = false
var first_launch_answered: bool = false
func to_dict() -> Dictionary
static func from_dict(data: Variant) -> Settings     # an invalid field takes its default; never null

class_name Stats extends RefCounted                   # GDD 13
const NEW_BEST_TIME := 1
const NEW_BEST_SCORE := 2
func started(level: int) -> int
func completed_count(level: int) -> int
func best_time(level: int) -> int                    # -1 until the first completion
func average_time(level: int) -> int                 # -1 until the first completion, rounded half up
func best_score(level: int) -> int                   # -1 until the first completion
func record_start(level: int) -> void
func record_completion(level: int, seconds: int, score: int) -> int   # bitmask of NEW_BEST_* per GDD 12.1, computed from
                                                                      # the bests before this completion; ties and a level's
                                                                      # first completion give no bit
func reset(in_progress_level: int) -> void           # -1 when no puzzle is in progress
func to_dict() -> Dictionary
static func from_dict(data: Variant) -> Stats        # defaults if invalid; never null

class_name LessonProgress extends RefCounted
func is_finished(lesson_id: String) -> bool
func mark_finished(lesson_id: String) -> bool        # true the first time
func finished_count() -> int
func to_dict() -> Dictionary
static func from_dict(data: Variant) -> LessonProgress   # keeps only ids matching ^lesson_[0-9]{2}$
```

## 5. puzzles (src/puzzles, puzzle-engine-dev)

Fixed in the Phase 2 task brief and built in Phase 2:

```gdscript
class_name Puzzle extends RefCounted
var id: String
var level: int
var seed: int
var givens: PackedInt32Array
var solution: PackedInt32Array
var hardest: StringName

class_name PuzzleId extends RefCounted
static func make(level: int, seed: int) -> String     # "<version>.<level>.<seed>", version 1
static func parse(id: String) -> Dictionary           # {"version", "level", "seed"} or {} if malformed

class_name SeededRng extends RefCounted               # our own PRNG, same output on every platform

class_name Solver extends RefCounted
static func count_solutions(grid: PackedInt32Array, limit: int = 2) -> int
static func solve(grid: PackedInt32Array) -> PackedInt32Array   # empty if none

class_name GradeResult extends RefCounted
var solved: bool
var level: int                 # -1 if stuck
var hardest: StringName
var step_count: int
var technique_counts: Dictionary

class_name TechniqueSolver extends RefCounted
static func grade(givens: PackedInt32Array) -> GradeResult

class_name PuzzleGenerator extends RefCounted
static func generate(level: int, seed: int) -> Puzzle   # deterministic, one solution, grades at level
static func generate_with_stats(level: int, seed: int) -> Dictionary   # {"puzzle", "attempts"}, for the timing tool
```

Built in Phase 2 beyond the fixed list, and part of the contract from now on:

- Seeds run from 0 to 4294967295 (`PuzzleId.MAX_SEED`). `generate` uses the low 32 bits of the seed and clamps the level to 0 to 4, so every returned id parses. `PuzzleId.VERSION` is 1. `parse` accepts only the exact form `make` writes (version 1, ASCII digits, no leading zeros, signs or spaces).
- `GradeResult`: a full valid grid gives solved, level 0 and an empty `hardest`; `technique_counts` lists only techniques used; when stuck, `hardest` is the hardest technique used before getting stuck.
- `TechniqueSolver` also has an instance API for the hint finder: `load_givens`, `load_state(cells, candidates)`, `run(max_level)`, `solves(max_level)`, `find_step(max_level)`, `apply_step`, `step_technique`, `step_cell`, `step_digit`, `step_eliminations`, `get_cells`, `get_candidates`, `result`, `technique_count`, `hardest_technique`, `is_solved`, static `technique_id`, and the constants `TECHNIQUES`, `TECHNIQUE_LEVELS`, `NO_STEP`, `MAX_LEVEL`.
- Inside X-Wing and Swordfish the search goes digit by digit, rows before columns for each digit, as documented in technique_solver.gd (a refinement GDD 11.1 allows).
- `SeededRng`: `set_seed`, `next_u32`, `next_int`, `shuffle`. `src/puzzles/grid_tables.gd` holds constant lookup tables (no class_name).
- Fixed copies of puzzles 1.0.1 and 1.4.1 in tests/puzzles catch any generator change that would break old ids. Changing the generator's output for a seed requires a new `PuzzleId.VERSION`.

Added in Phase 3:

```gdscript
class_name NextStep extends RefCounted                 # GDD 10.1 and 10.2
static func find(solution: PackedInt32Array, board: Board) -> Hint
# 1. a placed digit that differs from the solution (first in reading order): technique wrong_digit
# 2. otherwise the technique solver's next step not already done on the ring
# 3. otherwise the fallback
# Fills technique_name, text, lesson_title, targets, reasons, placement or eliminations.

static func placements_by(grid: PackedInt32Array, technique: StringName) -> Array[Vector2i]
# Every placement (x = cell, y = digit) that this one technique finds on this grid
# with candidates computed from the digits only. Used by the lesson data test.

class_name PuzzleSource extends RefCounted
const EXPERT_BANK_SIZE := 1000
static func pick_seed(level: int, random_u32: int) -> int
# Beginner to Hard: random_u32 itself (0 to PuzzleId.MAX_SEED). Expert: 1 + random_u32 % EXPERT_BANK_SIZE.
# App passes randi(); the function holds no state.
static func get_puzzle(level: int, seed: int) -> Puzzle
# Beginner to Hard: PuzzleGenerator.generate(level, seed).
# Expert with a seed from 1 to EXPERT_BANK_SIZE: the givens come from the bank, the solution from Solver.solve.
# Any other Expert seed, or a bank line that fails validation: PuzzleGenerator.generate(4, seed). Never crashes.
# Safe on a worker thread. Same level and seed always give the same puzzle.
```

Expert bank (Bart, Hard Stop 2). `src/puzzles/expert_bank.gd` (no class_name, preloaded by path) holds one constant: line k is the 81 givens, as the digits 0 to 9, of `PuzzleGenerator.generate(4, k)` for k from 1 to `EXPERT_BANK_SIZE`. It is code, not a data file, so nothing is read from disk. It is written only by `tools/puzzles/build_expert_bank.gd` (puzzle-engine-dev) and never edited by hand. A bank line is used only if it is exactly 81 ASCII digits and `Solver.count_solutions` gives exactly 1. The puzzle it gives has the normal id `"1.4.<k>"` and `hardest` from `TechniqueSolver.grade`. Tests check a sample of lines against the generator and check that every line is valid.

Givens floor (Bart, Hard Stop 2). Beginner and Easy puzzles keep at least the number of givens GDD section 11 sets for them; the generator stops removing givens there. There are no symmetric givens in v1. This changes the output of version 1 for Beginner and Easy seeds. Nothing has shipped and no save exists, so `PuzzleId.VERSION` stays 1 and the fixed copy of 1.0.1 in tests/puzzles is replaced once, in this change. The output for Medium, Hard and Expert must not change (the 1.4.1 fixed copy and the bank prove it).

`find` should be fast enough for the main thread on an Expert board (target under 50 ms on a phone). If it is not, the play screen runs it on a worker thread like this: pass a copy of the board (`duplicate_board`), keep Hint disabled while it runs, and when it returns, if the session's board changed in the meantime, throw the result away and look again before calling `buy_hint`. The player pays once, for a hint that matches the board.

## 6. skins (src/skins, grid-cell-artist; skin data by senior-graphic-designer)

### GameSkin and the skin files

```gdscript
class_name GameSkin extends Resource
@export var id: StringName
@export var display_name: String
@export var is_dark: bool
# Then one @export per row of the "Skin tokens" table in docs/DESIGN_SYSTEM.md,
# with exactly that name and type (Color or float). No other properties.
```

- `src/skins/game_skin.gd`: the class, owned by grid-cell-artist. It is generated by hand from the DESIGN_SYSTEM.md table. A test checks that every table row is a property and that both skin files set every property.
- `src/skins/pop_light.tres` and `src/skins/pop_dark.tres`: the values, owned by senior-graphic-designer. Ids `pop_light` (the default) and `pop_dark`.
- The contrast checker in tools/design/ reads these two files from Phase 3 on.

### Skins autoload

```gdscript
# res://src/skins/skin_service.gd, autoload "Skins"
signal skin_changed(skin: GameSkin)
const DEFAULT_ID := &"pop_light"
var current: GameSkin
func all() -> Array[GameSkin]                        # in display order: pop_light, pop_dark
func get_skin(id: StringName) -> GameSkin            # null if unknown
func apply(id: StringName) -> void                   # unknown ids fall back to DEFAULT_ID; emits skin_changed
```

### BoardPainter

The board drawing code. It draws a state; it holds no rules and handles no input.

```gdscript
class_name BoardDrawState extends RefCounted
var digits: PackedInt32Array
var givens: PackedInt32Array
var marks: PackedByteArray
var selected: int = -1
var mode: int = 0                       # GameSession.Mode
var peers: PackedInt32Array
var same_digit: PackedInt32Array
var conflicts: PackedInt32Array
var hint_targets: PackedInt32Array
var hint_reasons: PackedInt32Array
var hint_crosses: PackedInt32Array      # mark indices (cell * 9 + digit - 1) the hint says to cross (Hint.eliminations)
var lesson_marks: PackedInt32Array      # cells a lesson screen points at
var locked: bool = false                # completed board

class_name CellEffect extends RefCounted
enum Kind { PLACE, ERASE, CROSS, RESTORE, COMPLETE }
var cell: int
var digit: int
var kind: int
var progress: float                     # 0 to 1, driven by the caller with Motion timings

class_name BoardPainter extends RefCounted
static func board_square(rect: Rect2) -> Rect2                          # largest centered square
static func cell_rect(square: Rect2, cell: int, skin: GameSkin) -> Rect2
static func cell_at(square: Rect2, point: Vector2, skin: GameSkin) -> int   # -1 outside the cells
func draw_board(canvas: CanvasItem, square: Rect2, state: BoardDrawState, skin: GameSkin) -> void
func draw_effects(canvas: CanvasItem, square: Rect2, effects: Array[CellEffect], skin: GameSkin) -> void
```

The painter highlights each candidate in `hint_crosses` that is still shown open in its cell, in the look DESIGN_SYSTEM.md gives it (Bart, Hard Stop 2). A candidate already crossed is drawn as usual.

Ring layout A (reading rows) is the only layout. The hand X, the knockout outline and the Auto Cross mark follow DESIGN_SYSTEM.md. Performance target: a full redraw of a busy board under 8 ms on this laptop, redraws only when something changes, never one node per cell or candidate.

## 7. design (src/design, ui-motion-artist)

```gdscript
class_name ThemeFactory extends RefCounted
static func build(skin: GameSkin) -> Theme
# Built-in font only. Type variation names are constants here, one per style in DESIGN_SYSTEM.md,
# for example ThemeFactory.PAD_KEY, ThemeFactory.HINT_BUTTON, ThemeFactory.TITLE.
# Screens set theme_type_variation to these constants and never set colors, sizes or fonts themselves.

class_name Icons extends RefCounted
static func draw(canvas: CanvasItem, icon: StringName, rect: Rect2, color: Color) -> void
# icons: undo, erase, mode_place, mode_cross_out, hint, pause, play, settings, back, close, check, lock

class_name IconView extends Control
@export var icon: StringName
# draws Icons.draw with the theme's font color for its type variation; redraws on theme change

class_name Layout extends RefCounted
# The layout constants of DESIGN_SYSTEM.md section 4.6 (header height, band height, gaps, pad sizes, margins),
# in dp, as constants. PlayArea, the ui screens and the lesson player all read these; nobody repeats a number.
# Window shapes (DESIGN_SYSTEM.md 4.11, Bart Phase 6: split screen allowed, foldables lay out well):
enum Arrangement { STACKED, SIDE, TOO_SMALL }
static func stacked_board(content: Rect2, skin: GameSkin) -> float   # board side when stacked, 0 if it cannot stack
static func side_board(content: Rect2, skin: GameSkin) -> float      # board side with the side column, 0 if it cannot
static func arrangement(content: Rect2, skin: GameSkin) -> int       # content = safe rect minus page_margin on every side
# These must give the same answers as tools/design/layout_model.gd on every window it checks.

class_name Motion extends RefCounted
# durations and easing from DESIGN_SYSTEM.md as constants, plus helpers that return the Tween they start
static func press(node: CanvasItem) -> Tween
static func appear(node: CanvasItem) -> Tween
static func disappear(node: CanvasItem) -> Tween
static func effect_tween(owner: Node, effect: CellEffect, on_step: Callable) -> Tween

# res://src/design/app_icon.gd (no class_name; preloaded by path)
static func draw_full(canvas: CanvasItem, rect: Rect2) -> void
static func draw_background(canvas: CanvasItem, rect: Rect2) -> void
static func draw_foreground(canvas: CanvasItem, rect: Rect2) -> void
static func draw_monochrome(canvas: CanvasItem, rect: Rect2) -> void
static func foreground_outline(rect: Rect2) -> PackedVector2Array
```

How the look reaches the screen: at startup and on every `Skins.skin_changed`, `App` sets `get_tree().root.theme = ThemeFactory.build(Skins.current)`. Board drawing reads `Skins.current` directly and redraws on `skin_changed`. Skins switch live.

## 8. board (src/board and scenes/board, board-input-dev)

```gdscript
class_name BoardAction extends RefCounted
enum Kind { CELL, PAD, MODE, ERASE, UNDO }
var kind: int
var cell: int = -1
var digit: int = 0

class_name BoardView extends Control            # scenes/board/board_view.tscn
signal cell_pressed(cell: int)
var session: GameSession                        # set by the owner; the view listens to its signals
var lesson_marks: PackedInt32Array
func cell_rect_global(cell: int) -> Rect2       # for hint panel placement and lesson pointers
func play_effect(kind: int, cell: int, digit: int) -> void

class_name NumberPad extends Control            # scenes/board/number_pad.tscn: mode toggle, digits 1 to 9, Erase, Undo
signal digit_pressed(digit: int)
signal mode_pressed()
signal erase_pressed()
signal undo_pressed()
func set_mode(mode: int) -> void
func set_undo_enabled(enabled: bool) -> void
func set_locked(locked: bool) -> void           # after completion
func control_rect_global(control: StringName) -> Rect2   # &"mode", &"erase", &"undo", &"pad:<d>", for lesson pointers

class_name BoardController extends Node
signal action_applied(action: BoardAction, result: ActionResult)
signal action_rejected(action: BoardAction)     # only when a gate refuses it
var gate: Callable                              # optional: func(action: BoardAction) -> bool; lessons set it
func setup(session: GameSession, view: BoardView, pad: NumberPad) -> void
# Maps input to the session: cell -> select, pad -> press_digit, mode -> toggle_mode,
# erase -> erase, undo -> undo. Plays Audio.play_click() when result.click.
# Starts the matching CellEffect. Keeps the pad's mode and Undo state in step with the session.

class_name PlayArea extends Control             # scenes/board/play_area.tscn: BoardView + NumberPad + BoardController
var view: BoardView
var pad: NumberPad
var controller: BoardController
func setup(session: GameSession) -> void
func band_rect_global() -> Rect2                # the band above the board (DESIGN_SYSTEM.md 4.6): the play screen puts the
                                                # level sticker there, and lessons put their lesson card there. The hint
                                                # panel covers the screen's header row and the band together (DESIGN_SYSTEM.md 7.6)
func set_band_height(height: float) -> void     # the lesson player sizes the band to its card (DESIGN_SYSTEM.md 4.8);
                                                # the play screen leaves the Layout default
var header_height: float                       # play screen: Layout.HEADER_ROW; lessons: 0
func arrangement() -> int                       # Layout.Arrangement for the current rect
func header_rect_global() -> Rect2              # where the play screen puts its header row (HUD)
func info_zone_rect_global() -> Rect2           # header row plus band, minus space_s at the bottom: the hint panel
                                                # and the full board message cover exactly this
# PlayArea receives the whole safe rect and applies page_margin on all four sides (DESIGN_SYSTEM.md 4.11).
# STACKED: header row, band, board, gap, pad. SIDE: board on the left, a side column (header row, band, pad)
# on the right. TOO_SMALL: laid out stacked with sizes clamped at zero; the App shows the too small layer.
# Lays out the board and pad inside its own rect per DESIGN_SYSTEM.md: touch targets of 48 dp or more,
# fits and works at 320 by 568 dp, readability judged at 360 dp wide (Bart, Hard Stop 1; GDD AT-66).

class_name ScreenMetrics extends RefCounted
static func apply_dp_scale(window: Window) -> void   # called by App at startup and on size_changed: sets
                                                     # window.content_scale_size to the window size in dp, so one unit is one dp.
                                                     # Density: DisplayServer.screen_get_dpi() / 160 on Android; 1.0 on desktop,
                                                     # where the default window is 411 by 914 px (a typical phone in dp)
static func safe_rect(viewport: Viewport) -> Rect2   # the device safe area, in units (dp)
static func px_per_unit() -> float                   # device pixels per unit, for snapping lines to whole pixels
```

Input works with touch and mouse. Direct tapping on ring slots is not in v1. The board never decides a rule: it asks the session and draws what the session says.

## 9. audio (src/audio, audio-dev)

```gdscript
# res://src/audio/audio_service.gd, autoload "Audio"
var enabled: bool = true          # App sets it from Settings.sound
func play_click() -> void         # no-op when disabled

class_name ClickSynth extends RefCounted
static func build(mix_rate: int = 44100) -> AudioStreamWAV   # 50 to 90 ms, soft attack, quick decay, peak below full scale
```

## 10. lessons (src/lessons and scenes/lessons, lessons-dev; data by lesson-designer)

### Lesson data format

One JSON file per lesson: `src/lessons/data/lesson_01.json` to `lesson_05.json`, UTF-8. Loaded only with `FileAccess` and `JSON.parse_string`, validated field by field; nothing in the data can create an object or run code.

```json
{
  "format": 1,
  "id": "lesson_02",
  "number": 2,
  "title": "The ring and Cross Out",
  "subtitle": "Cross out what a cell cannot be",
  "solution": "314752698968431257...",
  "screens": [
    {
      "board": "3..7...9...8..12...",
      "start": {
        "selected": "r5c5",
        "mode": "cross_out",
        "placed": { "r2c3": 4 },
        "crossed": { "r5c5": [3, 9] }
      },
      "marked_cells": ["r4c5", "r7c5"],
      "marked_controls": ["mode"],
      "text": "A column can have each digit only once, too. This column has a 4 and a 6. Cross out 4 and 6.",
      "goal": {
        "order": "any",
        "steps": [ { "action": "pad", "digit": 4 }, { "action": "pad", "digit": 6 } ],
        "technique": ""
      },
      "next": { "start": "Cross out 4 and 6.", "after": { "pad:4": "Now cross out 6.", "pad:6": "Now cross out 4." } },
      "praise": "Nice work. The column is done.",
      "wrong": [
        { "match": { "action": "pad", "digits": [3, 9], "crossed": true }, "text": "{d} already has an X. Tapping it again would bring it back. {next}" },
        { "match": { "action": "pad", "digits": [2] }, "text": "Yes, this box has a 2. We will get to the box next. {next}" },
        { "match": { "action": "cell", "cells": ["r4c5"] }, "text": "That is the 4 in the column. Use the number pad to cross out digits. {next}" },
        { "match": { "action": "cell", "cells": "other" }, "text": "Keep this cell selected. {next}" },
        { "match": { "action": "mode" }, "text": "Stay in Cross Out mode for now. {next}" }
      ],
      "fallback": "{next}"
    }
  ]
}
```

Field rules:

- `board`: 81 characters, `1` to `9` for givens and `.` for empty, row by row. `solution`: 81 digits, one full solution consistent with every screen's board (lesson boards need not have a unique solution).
- Cells are `rXcY` strings, 1-based, as in LESSONS.md.
- `start.selected`: a cell (a given is allowed) or `null`. `start.mode`: `place` or `cross_out`. `placed`: digits placed by the player before the screen; they count as digits everywhere, including the data test. `crossed`: candidates already crossed by hand; they need not be ruled out (lesson 2 presets a wrong cross on purpose). All optional except `mode`.
- `marked_controls`: any of `mode`, `erase`, `undo`, `pad`, `pad:1` to `pad:9`.
- `goal.order`: `any` or `sequence`. `goal.steps`: each is `{ "action": "cell", "cell": "r5c5" }`, `{ "action": "pad", "digit": 9 }`, `{ "action": "mode" }`, `{ "action": "erase" }` or `{ "action": "undo" }`. A pad step means what it means in the current mode (cross or restore in Cross Out, place in Place) on the selected cell. Each step counts once.
- `goal.technique`: for a step that places a digit, the technique from GDD 11.3 that proves it (`last_empty_cell`, `hidden_single`, `naked_single`); otherwise empty.
- `next` (optional): fills `{next}`. If the most recent step done has an entry in `after` (keyed `pad:<d>`, `cell:rXcY`, `mode`, `erase` or `undo`), that text is used; otherwise `start` is used, which covers the moment before any step and any stage the data does not name.
- The gate checks each tap against the goal first: a tap that completes a step not yet done is right. Each step counts once, so repeating a step already done (for example tapping the already selected goal cell again) is a wrong tap. Only then is the `wrong` list checked.
- `wrong`: checked in order, first match wins. A match names an `action` and optionally `digits`, `cells` (a list, or `"other"` for any cell not named in an earlier entry or in the goal) and `crossed` (true or false: whether that digit is crossed in the selected cell at the moment of the tap). `{d}` is the tapped digit. No match uses `fallback`.
- Any tap that is not part of the step's answer is wrong and changes nothing: board, ring, selection and mode stay as they were (GDD 15.4, LESSONS.md section 8).
- Once a screen's answer is complete, the praise line and Next show, and every other tap on the board, the pad and the controls is ignored, with no text, until the player taps Next.

### Classes

```gdscript
class_name LessonScreen extends RefCounted     # one validated screen, cells already converted to indices
class_name Lesson extends RefCounted
var id: String
var number: int
var title: String
var subtitle: String
var solution: PackedInt32Array
var screens: Array[LessonScreen]

class_name LessonLibrary extends RefCounted
static func load_all() -> Array[Lesson]        # every file in src/lessons/data/, sorted by number; invalid files skipped with push_error
static func parse(json_text: String) -> Lesson # null if invalid; used by load_all and the tests

class_name LessonPlayer extends Control        # scenes/lessons/lesson_player.tscn, uses PlayArea with a gate
signal finished(lesson_id: String)             # the last step's answer is done (GDD 15.4)
signal closed()
func start(lesson: Lesson) -> void

class_name LessonsScreen extends Control       # scenes/lessons/lessons_screen.tscn: the list, with finished marks
```

Each screen builds its board with `Board.create`, applies `placed` and `crossed` directly, and wraps it with `GameSession.for_lesson`. The gate compares each `BoardAction` with the goal and the `wrong` list.

The lesson data test (tests/lessons) checks every file. Each screen's position is its `board` plus its `placed` digits. The test checks: the file parses; every position is legal and solvable and consistent with `solution`; preset `crossed` digits are not checked against the rules; every cell and control name is valid; every cross step crosses a digit that is ruled out in that cell at that moment and every restore step restores one that is not; every placement step's cell and digit appear in `NextStep.placements_by(grid, technique)` for the named technique.

## 11. ui (src/ui and scenes/ui, ui-systems-dev)

### App autoload

```gdscript
# res://src/ui/app.gd, autoload "App"
signal settings_changed()
signal stats_changed()
signal session_changed(session: GameSession)        # null when no puzzle is in progress
signal generation_started(level: int)
signal generation_finished(session: GameSession)

var settings: Settings
var stats: Stats
var lessons: LessonProgress
var session: GameSession                            # null when none

func has_puzzle_in_progress() -> bool
func start_new_puzzle(level: int) -> void           # picks seed = PuzzleSource.pick_seed(level, randi()), runs PuzzleSource.get_puzzle on a worker thread,
                                                    # creates the session, records Started, saves, emits generation_finished
func abandon_puzzle() -> void                       # deletes the saved puzzle and its undo history, sets session to null,
                                                    # emits session_changed(null); stats unchanged (GDD 13.2)
func on_puzzle_completed() -> CompletionResult      # GDD 12 order: records stats (new best bits first), deletes the saved
                                                    # puzzle, sets session to null, emits session_changed(null), and returns
                                                    # what the completion screen shows
func set_sound(on: bool) -> void
func set_skin(id: StringName) -> void
func set_auto_cross(on: bool) -> void               # also applies to the session in progress
func reset_stats() -> void
func record_lesson_finished(lesson_id: String) -> void
func answer_first_launch() -> void
func save_session() -> void
func goto(screen: StringName, payload: Variant = null) -> void
func go_back() -> void
```

Screens (scenes/ui, one scene and script each): main menu, level select, play (HUD, PlayArea, pause menu, hint panel, full board message, new puzzle confirm), completion, stats, settings (sound, skin picker, Auto Cross, Reset Stats with confirmation), first launch offer. The lessons list and lesson player are lessons-dev's scenes, opened through `App.goto(&"lessons")` and `App.goto(&"lesson", lesson)`.

The play screen drives the timer: it calls `session.add_time(delta)` in `_process` while the puzzle screen is showing and neither the pause menu nor another screen covers it. The hint panel and the full board message do not stop the timer (GDD 8). The Hint button calls `NextStep.find(session.solution, session.board)` and then `session.buy_hint(hint)` (section 5 if `find` runs on a worker thread).

Saving the puzzle in progress (GDD 14). `App.save_session()` writes `puzzle.json`, and runs:
- on the session's `board_changed` (every board change and undo), `mode_changed` and `hint_changed` (a hint bought or closed);
- after `set_auto_cross`;
- when the play screen is left, and on every lifecycle event below.
`save_session` never writes a session whose `is_completed` is true, and does nothing when `session` is null, so a finished puzzle can never come back as Continue (GDD 12, AT-51).

Auto Cross has one source of truth: `settings.auto_cross`. On resume and whenever the setting changes, App calls `session.set_auto_cross(settings.auto_cross)`, so the session's copy can never differ from the setting.

New puzzle (GDD 15.2): with a puzzle in progress, Start new in the confirm dialog calls `abandon_puzzle()` and then `start_new_puzzle(level)`. Keep playing changes nothing.

Android lifecycle in `App._notification`: on `NOTIFICATION_APPLICATION_PAUSED`, `NOTIFICATION_APPLICATION_FOCUS_OUT` and `NOTIFICATION_WM_CLOSE_REQUEST`, save everything and open the pause menu if a puzzle is showing. On `NOTIFICATION_WM_GO_BACK_REQUEST`, go back one screen; on the play screen Back opens the pause menu, and in the pause menu Back resumes (GDD 8).

Window shapes (GDD 2.4 and 8.1, DESIGN_SYSTEM.md 4.11). App re-checks `Layout.arrangement` on every `size_changed`. Entering TOO_SMALL shows the too small layer above every screen, and on the play screen opens the pause menu (timer stops) and calls `save_session()`. While the layer shows, Back in the pause menu does nothing; elsewhere Back does what the screen underneath does. A puzzle that finishes generating while too small opens paused. Leaving TOO_SMALL removes the layer and shows the screen underneath as it was left. project.godot sets `application/config/quit_on_go_back=false`.

The first launch answer is stored in `settings.json` (`Settings.first_launch_answered`). If that file is unreadable the lesson 1 offer shows once more, which is harmless.

## 12. save (src/save, ui-systems-dev)

Four files in `user://`, each its own part, so damage to one never loses the others (GDD 14):

| File | Contents | Class |
| --- | --- | --- |
| user://settings.json | `Settings.to_dict()` | Settings |
| user://stats.json | `Stats.to_dict()` | Stats |
| user://lessons.json | `LessonProgress.to_dict()` | LessonProgress |
| user://puzzle.json | `GameSession.to_dict()`, absent when no puzzle is in progress | GameSession |

Every file is `{"format": 1, "data": {...}}`.

```gdscript
class_name SaveStore extends RefCounted
const MAX_BYTES_PUZZLE := 16777216               # 16 MiB: undo history has no limit (GDD 7)
const MAX_BYTES_OTHER := 262144                  # 256 KiB for settings, stats and lessons
static func read(path: String, max_bytes: int) -> Variant   # the "data" value, or null when missing, too large, not JSON, or the wrong format
static func write(path: String, data: Dictionary, max_bytes: int = MAX_BYTES_PUZZLE) -> bool
# atomic: write path + ".tmp", flush, close, then rename over path. Refuses data over max_bytes (UTF-8 bytes),
# so the last valid file stays. App writes through SaveWriter (src/save/save_writer.gd), which serializes and
# writes on a worker thread, at most once per frame; lifecycle events and leaving the play screen write at once.
static func remove(path: String) -> void
```

Rules (security, checked by the security reviewer):

- JSON only, through Godot's `JSON` class. Never `str_to_var`, `bytes_to_var`, `ResourceLoader`, `load()` or anything that can create objects from file data.
- `from_dict` validates every field: type, range, array length, allowed values, and cross checks (a session's digits agree with its givens; its solution is a complete valid grid that agrees with its givens; undo steps reference valid cells and marks; `hints_bought` is 0 to 5; a saved hint has cells 0 to 80, mark indices 0 to 728 and a technique id from section 2). Invalid data falls back to defaults, or to no puzzle in progress, and never crashes.
- Undo steps are stored compactly (flat int arrays, not one dictionary per mark change). A test saves and loads a session with a 20,000 step undo history and checks it stays under `MAX_BYTES_PUZZLE`.
- `user://` only. No other paths.

## 13. Platform (platform-dev)

- Name Sudoku. Android package `com.bartbasi.sudoku`. Portrait only. Compatibility renderer.
- Stretch mode `canvas_items`, aspect `expand`, base size 411 by 914 with no window override, so the desktop window is a typical phone in dp. `ScreenMetrics.apply_dp_scale` makes one unit one dp on every device.
- Export only game files: exclude `tests/*`, `tools/*`, `docs/*`, `build/*`. The lesson data is JSON, not a Godot resource, so the export preset must include `src/lessons/data/*.json` explicitly (and the bank file, if Bart picks one).
- No Android permissions in debug or release.
- Launcher icons are rendered at build time from `src/design/app_icon.gd` into build/ and never committed.
- No boot splash image; a plain background color from Pop.

## 14. Main flows

- **Place a digit:** NumberPad `digit_pressed` -> BoardController (gate if any) -> `session.press_digit` -> session emits `board_changed`, then maybe `completed` -> BoardView redraws and plays the effect -> controller plays the click -> App saves on `board_changed` (never a completed session).
- **New puzzle:** level select -> confirm dialog if one is in progress (Start new calls `App.abandon_puzzle`) -> `App.start_new_puzzle` -> worker thread `PuzzleSource.get_puzzle` -> `GameSession.create` with `settings.auto_cross` -> `Stats.record_start` -> save -> play screen.
- **Hint:** Hint button (enabled only when `can_buy_hint`) -> `NextStep.find` -> `session.buy_hint` -> `hint_changed` -> BoardView marks targets and reasons and highlights the candidates to cross (`hint.eliminations`), the hint panel shows the text.
- **Completion:** `session.completed` -> `App.on_puzzle_completed` (stats, delete the save, session null) -> completion screen shows the returned `CompletionResult`: level, time, score parts, hints used and any New best label.
- **Resume:** App startup -> `SaveStore.read` -> `GameSession.from_dict` -> `session.set_auto_cross(settings.auto_cross)` -> main menu shows Continue.
- **Skin change:** settings -> `App.set_skin` -> `Skins.apply` -> `skin_changed` -> App rebuilds the theme, boards redraw.
- **Lesson step:** NumberPad or BoardView -> BoardController -> gate (LessonPlayer) -> right taps apply to the lesson session; wrong taps show text and change nothing.

## 15. Tests

`tests/<area>/test_*.gd`, one folder per area, owned by that area's developer, run with `timeout 900 godot --headless --path . --script res://tests/run_tests.gd`. After a fresh clone run `godot --headless --path . --import` once so class names resolve. Phase 3 requires: core covers every GDD rule and every pure-logic acceptance test; puzzles covers the generator, grading, every technique, the givens floor, the next-step finder and the Expert bank; lessons covers every lesson file; save covers corrupt, truncated, wrong-typed and out-of-range data; skins covers the token table against GameSkin and both skin files.

## 16. Ownership notes added by this contract

- src/skins/: the scripts belong to grid-cell-artist; `pop_light.tres` and `pop_dark.tres` belong to senior-graphic-designer.
- scenes/lessons/ holds the lessons list and the lesson player (lessons-dev).
- docs/GENERATION_TIMING.md belongs to puzzle-engine-dev.
- `ScreenMetrics` (src/board) is used by every screen.
