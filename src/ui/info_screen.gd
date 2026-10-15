extends UiScreen
## The Info screen (GDD 15.5, DESIGN_SYSTEM.md 7.16): everything a player
## needs to know, in one card per section: the heading, then one wrapping
## label per paragraph. A line starting with a dash is its own label, as a
## list line. The list scrolls up and down, never sideways, and opens at the
## top. Back (the title row's or Android's) returns to the title screen.
##
## The words are the GDD's, word for word. The GDD's bracketed section
## numbers are for the team and are not here. tests/ui/test_title_screens.gd
## compares this text with GDD 15.5, so a change there fails until this
## follows it.
## Owner: ui-systems-dev.

## [heading, [paragraph, ...]] in GDD order.
const SECTIONS: Array[Array] = [
	["How to play", [
		"Fill the board so that every row, every column and every box holds the digits 1 to 9, each exactly once. A box is one of the nine 3 by 3 squares with the heavier borders.",
		"Every puzzle has exactly one answer, and you can always reach it by reasoning. You never need to guess.",
		"Tap PLAY to start. It brings back the puzzle you were playing, or starts a new one at the level you last started. The very first time, that is Easy.",
	]],
	["Getting around", [
		"The title screen has PLAY, MENU, INFO and ABOUT. Back on the title screen closes the game. Your puzzle is saved.",
		"MENU on the title screen opens the main menu. During a puzzle, tap the Pause button, then Menu. You also get there from Menu when you finish a puzzle. The main menu has Continue (when a puzzle is in progress), New puzzle, Lessons, Stats and Settings. Back on the main menu takes you to the title screen.",
	]],
	["The board", [
		"Some digits are there from the start. They are called givens. They look different from the digits you place, and they cannot be changed.",
		"Tap any cell to select it. Its row, column and box light up. If the cell holds a digit, every other cell with that digit lights up too, so you can see where that digit already is.",
	]],
	["The candidate ring", [
		"Every empty cell shows the digits 1 to 9 around its inside edge: 1, 2, 3 and 4 across the top, 5 on the left, 6 on the right, and 7, 8 and 9 across the bottom. These are the candidates: the digits that might still go in that cell.",
		"A digit is ruled out for a cell when the cell's row, column or box already holds it. Cross out the digits you rule out. A crossed digit stays readable, so you always see what you crossed. When you have crossed out all but one digit correctly, that last digit goes in the cell.",
		"Example: a cell's row holds 9 and 3, its column holds 4 and 6, and its box holds 2, 3 and 4. Cross out 2, 3, 4, 6 and 9. That leaves 1, 5, 7 and 8 open.",
		"The game never checks your crosses. You can cross out any digit, even all nine, and bring it back later.",
		"If you would rather keep the candidates in your head, turn off Show candidates in Settings. The rings are hidden, and your crosses are kept for when you turn it back on.",
	]],
	["Place and Cross out", [
		"The pad has the digits 1 to 9 and a switch with two modes, Place and Cross out. The switch and the selected cell both show which mode is on.",
		"Place: tap a digit to put it in the selected cell. Tap a different digit to replace it. While a cell holds a digit, its ring is hidden.",
		"Cross out: tap a digit to cross it out in the selected cell's ring. Tap it again to bring it back. Cross out works only on empty cells.",
		"Switching modes keeps your selected cell. You can place a digit even if you crossed it out.",
		"With Show candidates off, the switch is hidden and every digit you tap is placed.",
	]],
	["Erase and Undo", [
		"Erase removes a digit you placed in the selected cell. Givens cannot be erased. When the digit goes, the ring comes back with your crosses exactly as you left them.",
		"Erase does not clear crosses. To bring back a crossed digit, tap it again in Cross out mode.",
		"Undo takes back your last change: a digit placed, replaced or erased, or a candidate crossed out or brought back. Tap it again to go further back, all the way to the start of the puzzle. Undo selects the cell it changed. Your undo history is kept when you close the game. Undo never gives back the cost of a hint.",
	]],
	["Auto Cross", [
		"Auto Cross is a setting, and it is off unless you turn it on. Crossing out by hand is how you learn to see the board.",
		"While it is on, the game crosses out every candidate that a digit in the same row, column or box rules out. When that digit goes and nothing else rules the candidate out, Auto Cross brings it back. Its X looks different from yours. It never changes a digit you crossed out or brought back yourself. When you erase a digit, your own crosses come back exactly as you left them, and Auto Cross updates its crosses to match the board.",
		"Auto Cross trusts every digit on the board, even a wrong one. A wrong digit makes it cross out candidates that should stay open.",
		"Turning it off leaves its crosses where they are. Turning it on again updates them. Auto Cross does not change your score. It is always off in lessons.",
	]],
	["Mistakes", [
		"If the same digit is in a row, column or box more than once, every cell involved is marked. That is the only check while you play. A wrong digit that clashes with nothing is not marked. A hint will point it out, at the usual cost.",
		"Marks cost no points. They go away as soon as the clash is fixed.",
		"If the board is full but some digits clash, the puzzle is not finished. Fix the marked cells. A full board with no clash is always the right answer.",
	]],
	["Timer and pause", [
		"The timer starts when the board appears. The time it takes to make the puzzle does not count. The timer runs only while you can see the board.",
		"Tap the Pause button, or press Back, to open the pause menu. It hides the board and stops the timer. It has Resume, Settings and Menu.",
		"When you leave the game, or another app takes over the screen, the game pauses too, and the pause menu is waiting when you come back. Time while the game is closed never counts.",
		"If the game's window gets too small to play in, a message says so and the game pauses until the window is bigger again.",
	]],
	["Score", [
		"Each puzzle starts with points for its level. The score shows them while you play. It goes down only when you buy a hint, and never below zero. Time does not lower it.",
		"Finish faster than the level's par time, a target time for the level, and you also get a time bonus. The bonus is the level's points times the part of the par time you had left, rounded down. At the par time or slower there is no bonus. Your final score is your points after hints plus the time bonus.",
		"- Beginner: 100 points, a hint costs 20, par time 8:00",
		"- Easy: 200 points, a hint costs 40, par time 12:00",
		"- Medium: 400 points, a hint costs 80, par time 20:00",
		"- Hard: 700 points, a hint costs 140, par time 30:00",
		"- Expert: 1000 points, a hint costs 200, par time 45:00",
		"A hint costs a fifth of the level's points, so five hints use them all up.",
		"Example: you finish an Easy puzzle in 9:00 with one hint. Your points are 200 minus 40 for the hint, which is 160. The par time is 12:00, so you had 3:00 left, a quarter of it. The time bonus is a quarter of 200, which is 50. Your score is 160 plus 50, which is 210.",
	]],
	["Hints", [
		"Stuck? Tap the Hint button. A hint never fills anything in.",
		"If a digit you placed is wrong, the hint points to it so you can erase it. Otherwise the hint shows the next step you can work out. It marks the cells involved, highlights any candidates to cross out, explains the step in a sentence or two and names the technique. A technique is a way of reasoning that finds a digit or rules candidates out. For the techniques the lessons teach, the hint also names the lesson.",
		"The hint stays on screen until you close it, place, replace or erase a digit, or tap Undo. You can cross out candidates while it shows. If you close a hint and ask again, the new hint costs again.",
		"With Show candidates off, a hint that says to cross out candidates shows just those candidates while it is on screen.",
		"The Hint button is off while a hint is showing, once the puzzle is finished, and when your score is lower than a hint costs. That happens after five hints, when your score is 0.",
	]],
	["Levels", [
		"There are five levels: Beginner, Easy, Medium, Hard and Expert, all open from the start. To pick one, open the main menu and tap New puzzle. If a puzzle is in progress, the game asks first. The old puzzle then counts as started, not completed.",
		"A level is set by the hardest technique the puzzle needs, not by how many digits it starts with.",
		"- Beginner: last empty cell, a row, column or box with one empty cell left, and hidden single, a digit that fits in only one cell of a row, column or box",
		"- Easy: also naked single, a cell where every digit but one is ruled out",
		"- Medium, Hard and Expert: patterns across several cells. A hint names and explains each one when you need it.",
	]],
	["Finishing and stats", [
		"A puzzle is finished the moment the board is full with no clash. The timer stops, and you see the level, your time, your points after hints, your time bonus, your score and the number of hints you used. Then choose Play again for another puzzle at the same level, or Menu.",
		"Stats, on the main menu, show for each level: Started (puzzles whose board appeared, including ones you left unfinished), Completed, Best time, Average time (of completed puzzles) and Best score. They also show how many of the five lessons you have finished.",
		"When a result beats your best at that level, the finish screen says New best time or New best score, or both. A tie is not a new best. The first puzzle you finish at a level shows neither, because there is nothing to beat yet.",
	]],
	["Lessons", [
		"Five short lessons teach the basics: 1 How Sudoku works, 2 The ring and Cross Out, 3 Last empty cell, 4 Hidden single, 5 Naked single. Open them from Lessons on the main menu. The first time you tap PLAY, the game offers lesson 1.",
		"In a lesson, a tap that is not the answer changes nothing and a short note tells you why, so you cannot fail. Lessons have no timer, score or hints, and Auto Cross is always off. Your puzzle in progress waits, with its timer stopped.",
	]],
	["Settings", [
		"Settings opens from the main menu and from the pause menu.",
		"- Sound: a click when you place a digit, or cross out a candidate or bring it back. On at first.",
		"- Show candidates: shows the candidate ring in empty cells. Turn it off to hide every ring and the Place and Cross out switch, so every tap places a digit. Your crosses are kept, and Auto Cross keeps working, so turning it back on shows the rings as they are now. Lessons always show the ring. On at first.",
		"- Auto Cross: see above. Off at first. You can change it while candidates are hidden.",
		"- Skin: Light, the first choice, or Dark.",
		"- Reset stats: clears the stats of every level after you confirm. Your lesson progress stays. This cannot be undone.",
	]],
]

## The scrolling list, for tests.
var scroll: ScrollContainer = null
## The section cards, in order.
var cards: Array[PanelContainer] = []


func build() -> void:
	var s: GameSkin = skin()
	var stack: VBoxContainer = UiKit.vbox(s.space_s)
	column.add_child(stack)
	stack.add_child(UiKit.title_row("Info", s.space_s, _on_back_pressed))
	scroll = ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(scroll)
	var list: VBoxContainer = UiKit.vbox(s.space_m)
	list.name = "List"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for section: Array in SECTIONS:
		var card: PanelContainer = _card(s, section[0], section[1])
		list.add_child(card)
		cards.append(card)
	var shadow_room: Control = Control.new()
	shadow_room.custom_minimum_size.y = s.shadow_offset
	shadow_room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	list.add_child(shadow_room)


func _card(s: GameSkin, heading: String, paragraphs: Array) -> PanelContainer:
	var card: PanelContainer = UiKit.panel(ThemeFactory.CARD)
	card.name = heading.replace(" ", "")
	var inside: VBoxContainer = UiKit.vbox(s.space_s)
	card.add_child(inside)
	var title: Label = UiKit.label(ThemeFactory.HEADING, heading, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inside.add_child(title)
	for paragraph: Variant in paragraphs:
		var line: Label = UiKit.label(ThemeFactory.BODY, String(paragraph), true)
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		inside.add_child(line)
	return card
