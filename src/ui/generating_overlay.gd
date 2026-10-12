extends Container
## Making a puzzle (DESIGN_SYSTEM.md 7.14), over the current screen while a
## new puzzle is made on the worker thread.
##
## From the first frame it is a clear layer that takes every tap and draws
## nothing. After Motion.MAKING_DELAY the SCRIM fades in and a DIALOG card
## appears with the level on a STICKER, the hero rocking (Motion.rock) and
## "Making your puzzle." Once the card shows it stays at least
## Motion.MAKING_MIN: App asks hold_left() before it opens the play screen,
## then calls leave(). Nothing on it is tappable.
## No class_name: App preloads it.
## Owner: ui-systems-dev.

const TEXT: String = "Making your puzzle."
## The hero's box on the card (7.14).
const HERO_SIDE: float = 64.0

## The level being made, shown on the sticker. Set before it enters the tree.
var level: int = Levels.BEGINNER
## The skin in use. App sets it before the overlay enters the tree.
var skin: GameSkin = null

var _scrim: Panel = null
var _card: PanelContainer = null
var _hero: HeroIcon = null
var _rock: Tween = null
var _elapsed: float = 0.0
## Seconds since the card appeared; negative while it has not.
var _shown_for: float = -1.0
var _leaving: bool = false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
	ensure_built()


## Builds the scrim and the card, hidden, once. _ready calls it; App and
## tests may call it before the overlay enters the tree.
func ensure_built() -> void:
	if _card != null:
		return
	if skin == null:
		skin = UiKit.skin_of(self)
	var s: GameSkin = skin
	_scrim = Panel.new()
	_scrim.name = "Scrim"
	_scrim.theme_type_variation = ThemeFactory.SCRIM
	_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scrim.visible = false
	add_child(_scrim)
	_card = UiKit.panel(ThemeFactory.DIALOG)
	_card.name = "Card"
	_card.visible = false
	var stack: VBoxContainer = UiKit.vbox(s.space_m)
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	_card.add_child(stack)
	var sticker: Control = UiKit.sticker(ThemeFactory.STICKER, ThemeFactory.STICKER_LABEL, Levels.name_of(level), s.sticker_tilt)
	sticker.name = "LevelSticker"
	sticker.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stack.add_child(sticker)
	_hero = HeroIcon.new()
	_hero.name = "Hero"
	_hero.gap = 0.0
	_hero.custom_minimum_size = Vector2(HERO_SIDE, HERO_SIDE)
	_hero.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_hero.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stack.add_child(_hero)
	var line: Label = UiKit.label(ThemeFactory.BODY, TEXT)
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(line)
	add_child(_card)


func _process(delta: float) -> void:
	step(delta)


## Moves the overlay's clock on by seconds: the card shows once
## MAKING_DELAY has passed. _process calls it; tests call it directly.
func step(seconds: float) -> void:
	if _leaving:
		return
	ensure_built()
	_elapsed += seconds
	if _shown_for >= 0.0:
		_shown_for += seconds
	elif _elapsed >= Motion.MAKING_DELAY:
		_show_card()


## True once the scrim and the card show.
func is_card_shown() -> bool:
	return _shown_for >= 0.0


## Seconds the card must still stay before the play screen may come in.
## 0 when the card never showed or has shown MAKING_MIN already.
func hold_left() -> float:
	if _shown_for < 0.0:
		return 0.0
	return maxf(0.0, Motion.MAKING_MIN - _shown_for)


## The puzzle is ready and the play screen is coming in: the overlay stops
## taking taps at once. With no card it goes now; otherwise the card and the
## scrim go (Motion.disappear) and then it frees itself.
func leave() -> void:
	if _leaving:
		return
	_leaving = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stop_rock()
	if not is_card_shown() or not is_inside_tree():
		queue_free()
		return
	Motion.disappear(_scrim)
	var tween: Tween = Motion.disappear(_card)
	tween.finished.connect(queue_free)


func _show_card() -> void:
	_shown_for = 0.0
	Motion.appear(_scrim)
	Motion.appear(_card)
	_rock = Motion.rock(_hero)


func _stop_rock() -> void:
	if _rock != null and _rock.is_valid():
		_rock.kill()
	_rock = null
	if _hero != null:
		_hero.rotation = 0.0


func _exit_tree() -> void:
	_stop_rock()


func _notification(what: int) -> void:
	if what != NOTIFICATION_SORT_CHILDREN or _card == null:
		return
	fit_child_in_rect(_scrim, Rect2(Vector2.ZERO, size))
	var safe: Rect2 = UiKit.safe_rect_local(self)
	var card_size: Vector2 = _card.get_combined_minimum_size()
	var widest: float = minf(UiSizes.DIALOG_MAX_W, safe.size.x - 2.0 * skin.space_l)
	card_size.x = maxf(card_size.x, widest)
	fit_child_in_rect(_card, Rect2(safe.position + (safe.size - card_size) * 0.5, card_size))
