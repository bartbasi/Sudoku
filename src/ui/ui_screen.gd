class_name UiScreen
extends Control
## Base of every screen in scenes/ui. App.goto() sets app and calls open()
## before the screen enters the tree; _ready() paints the page and calls
## build(), where each screen makes its controls inside column.
##
## Hooks App calls: handle_back() (return true when the screen used Back
## itself, for example to close a dialog) and on_shown() (the screen is
## showing again after the one above it closed).
## Owner: ui-systems-dev.

var app: AppService = null
var payload: Variant = null
## The page background, edge to edge (PAGE).
var page: Panel = null
## The safe content column (DESIGN_SYSTEM.md 4.5).
var column: ScreenColumn = null


func open(new_payload: Variant) -> void:
	payload = new_payload


func _ready() -> void:
	ensure_built()


## Paints the page and builds the screen, once. App calls it right after
## adding the screen, so a screen is complete even where _ready() has not run
## yet (the headless test runner has no running tree).
func ensure_built() -> void:
	if page != null:
		return
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page = Panel.new()
	page.name = "Page"
	page.theme_type_variation = ThemeFactory.PAGE
	page.mouse_filter = Control.MOUSE_FILTER_STOP
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(page)
	column = ScreenColumn.new()
	column.name = "Column"
	column.margin = skin().page_margin
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(column)
	build()


## Override: make the screen's controls, adding them to column.
func build() -> void:
	pass


func handle_back() -> bool:
	return false


func on_shown() -> void:
	pass


## The skin in use, for spacing tokens and custom drawing.
func skin() -> GameSkin:
	if app != null:
		return app.current_skin()
	return load("res://src/skins/pop_light.tres") as GameSkin


## Back from the title row's back button.
func _on_back_pressed() -> void:
	if app != null:
		app.go_back()
