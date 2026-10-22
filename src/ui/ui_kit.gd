class_name UiKit
extends RefCounted
## Small builders the screens share. Every control they make gets its look
## from a ThemeFactory type variation only: no colors, sizes or fonts are set
## here, apart from minimum sizes taken from Layout, UiSizes and the skin.
## Owner: ui-systems-dev.

const TouchTarget := preload("res://src/ui/touch_target.gd")


## A label in a text style. The text goes through display_text, so the roles
## set in capitals show in capitals.
static func label(variation: StringName, text: String, wrap: bool = false) -> Label:
	var node: Label = Label.new()
	node.theme_type_variation = variation
	node.text = ThemeFactory.display_text(variation, text)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if wrap:
		node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		node.custom_minimum_size.x = 1.0
	return node


## Sets text on a label made by label(), in its style's letter case.
static func set_text(node: Label, text: String) -> void:
	node.text = ThemeFactory.display_text(node.theme_type_variation, text)


## A button with a text label and an optional icon (Icons).
static func button(variation: StringName, text: String, height: float, icon: StringName = &"") -> Button:
	var node: Button = Button.new()
	node.theme_type_variation = variation
	node.text = ThemeFactory.display_text(variation, text)
	node.custom_minimum_size.y = height
	node.focus_mode = Control.FOCUS_NONE
	if icon != &"":
		node.icon = Icons.texture(icon, Icons.SIZE_BUTTON)
	node.pressed.connect(func() -> void: Motion.press(node))
	return node


## A small text button: a face of the given height (under 48 dp), only as
## wide as its label, in a 48 dp touch area (DESIGN_SYSTEM.md 4.4). Returns
## the touch area; its button is touch.button. Used for Buy me a coffee.
static func small_button(variation: StringName, text: String, face: float) -> TouchTarget:
	var touch: TouchTarget = TouchTarget.new()
	touch.set_button(button(variation, text, face))
	return touch


## Buy me a coffee (title, main menu, pause menu, settings, completion,
## About): the small secondary button, a Layout.ICON_FACE face only as wide
## as its label in a 48 dp touch area, centered in its column. Returns the
## touch area, named Coffee; its face is touch.button, named CoffeeButton.
## The screen connects the press.
static func coffee_button() -> TouchTarget:
	var touch: TouchTarget = small_button(ThemeFactory.BUTTON_SECONDARY, "Buy me a coffee", Layout.ICON_FACE)
	touch.name = "Coffee"
	touch.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	touch.button.name = "CoffeeButton"
	return touch


## An icon button (back, close, pause): a 40 dp face in a 48 dp touch area
## (DESIGN_SYSTEM.md 4.4). Returns the touch area; its button is
## touch.button.
static func icon_button(icon: StringName, face: float = Layout.ICON_FACE) -> TouchTarget:
	var node: Button = Button.new()
	node.theme_type_variation = ThemeFactory.ICON_BUTTON
	node.icon = Icons.texture(icon, Icons.SIZE_ICON_BUTTON)
	node.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.expand_icon = true
	node.custom_minimum_size = Vector2(face, face)
	node.focus_mode = Control.FOCUS_NONE
	node.pressed.connect(func() -> void: Motion.press(node))
	var touch: TouchTarget = TouchTarget.new()
	touch.set_button(node)
	return touch


## A panel in a panel style (CARD, STICKER and so on).
static func panel(variation: StringName) -> PanelContainer:
	var node: PanelContainer = PanelContainer.new()
	node.theme_type_variation = variation
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


## A sticker: a panel holding one label, tilted counterclockwise by tilt
## degrees around its center. A container resets the rotation of the
## children it lays out, so the face sits in a plain holder that never does;
## the holder takes the untilted size and keeps the face centered in it.
## Returns the holder; sticker_label() finds the label.
static func sticker(panel_variation: StringName, label_variation: StringName, text: String, tilt: float) -> Control:
	var face: PanelContainer = panel(panel_variation)
	face.name = "Face"
	face.add_child(label(label_variation, text))
	face.rotation = -deg_to_rad(tilt)
	var holder: Control = Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(face)
	var fit: Callable = func() -> void:
		var need: Vector2 = face.get_combined_minimum_size()
		holder.custom_minimum_size = need
		face.size = need
		face.position = ((holder.size - need) * 0.5).max(Vector2.ZERO)
		face.pivot_offset = need * 0.5
		holder.pivot_offset = holder.size * 0.5
	face.minimum_size_changed.connect(fit)
	holder.resized.connect(fit)
	fit.call()
	return holder


## The label of a sticker made by sticker().
static func sticker_label(sticker_node: Control) -> Label:
	return sticker_node.get_node(^"Face").get_child(0) as Label


static func vbox(separation: float) -> VBoxContainer:
	var node: VBoxContainer = VBoxContainer.new()
	node.add_theme_constant_override(&"separation", roundi(separation))
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


static func hbox(separation: float) -> HBoxContainer:
	var node: HBoxContainer = HBoxContainer.new()
	node.add_theme_constant_override(&"separation", roundi(separation))
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


## content with room for its hard shadow under it (the skin's
## shadow_offset), with no separation between: a VBox, centered vertically
## when it is given more height than it needs.
static func with_shadow_room(content: Control, s: GameSkin) -> VBoxContainer:
	var block: VBoxContainer = vbox(0.0)
	block.alignment = BoxContainer.ALIGNMENT_CENTER
	block.add_child(content)
	var room: Control = Control.new()
	room.name = "ShadowRoom"
	room.custom_minimum_size.y = s.shadow_offset
	room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	block.add_child(room)
	return block


## The title row of every screen but play (DESIGN_SYSTEM.md 4.9): a back
## button at the left and the title beside it, Layout.HEADER_ROW tall.
static func title_row(title: String, gap: float, on_back: Callable) -> HBoxContainer:
	var row: HBoxContainer = hbox(gap)
	row.custom_minimum_size.y = Layout.HEADER_ROW
	var back: TouchTarget = icon_button(Icons.BACK)
	back.button.pressed.connect(on_back)
	back.name = "Back"
	row.add_child(back)
	var heading: Label = label(ThemeFactory.TITLE, title)
	heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	heading.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(heading)
	return row


## m:ss, or h:mm:ss from one hour (GDD 8). Negative counts as 0.
static func format_time(seconds: int) -> String:
	var total: int = maxi(seconds, 0)
	var hours: int = total / 3600
	var minutes: int = (total / 60) % 60
	var secs: int = total % 60
	if hours > 0:
		return "%d:%02d:%02d" % [hours, minutes, secs]
	return "%d:%02d" % [minutes, secs]


## A stat value: "-" for -1, the number otherwise (GDD 13.1).
static func stat_number(value: int) -> String:
	return "-" if value < 0 else str(value)


static func stat_time(value: int) -> String:
	return "-" if value < 0 else format_time(value)


## The safe area (ScreenMetrics) in node's own coordinates. Inside a screen
## with a safe_rect_override, that rect instead.
static func safe_rect_local(node: Control) -> Rect2:
	var screen: UiScreen = screen_of(node)
	if screen != null and screen.safe_rect_override.has_area():
		var offset: Vector2 = node.get_global_rect().position - screen.get_global_rect().position
		var local: Rect2 = Rect2(screen.safe_rect_override.position - offset, screen.safe_rect_override.size)
		return local.intersection(Rect2(Vector2.ZERO, node.size)) if node.size != Vector2.ZERO else local
	var viewport: Viewport = node.get_viewport()
	if viewport == null:
		return Rect2(Vector2.ZERO, node.size)
	return safe_rect_in(ScreenMetrics.safe_rect(viewport), node.get_global_rect().position, screen_slide(node), node.size)


## The math behind safe_rect_local: safe (viewport coordinates) seen from a
## node of node_size whose top left is at global_origin while its screen is
## slid by slide, measured from the screen's resting place.
static func safe_rect_in(safe: Rect2, global_origin: Vector2, slide: Vector2, node_size: Vector2) -> Rect2:
	var local: Rect2 = Rect2(safe.position - (global_origin - slide), safe.size)
	return local.intersection(Rect2(Vector2.ZERO, node_size)) if node_size != Vector2.ZERO else local


## How far the screen holding node is moved from its resting place right
## now (App slides each new screen in from the right). Screens are full rect,
## so at rest this is zero. Layout measures from the resting place, so the
## column does not lose the slide's width on the right.
static func screen_slide(node: Node) -> Vector2:
	var at: Node = node
	while at != null:
		if at is UiScreen:
			return (at as UiScreen).position
		at = at.get_parent()
	return Vector2.ZERO


## The UiScreen that holds node (node itself if it is one), or null.
static func screen_of(node: Node) -> UiScreen:
	var at: Node = node
	while at != null:
		if at is UiScreen:
			return at as UiScreen
		at = at.get_parent()
	return null


## The content box of the window node is in (DESIGN_SYSTEM.md 4.11): the
## safe area inset by page_margin on every side, in the coordinates of node's
## screen (or of node, outside any screen). Never negative.
static func content_box(node: Control, skin: GameSkin) -> Rect2:
	var whole: Control = screen_of(node)
	if whole == null:
		whole = node
	var box: Rect2 = safe_rect_local(whole).grow(-skin.page_margin)
	box.size = box.size.max(Vector2.ZERO)
	return box


## The window's arrangement (Layout.Arrangement) for node, by the shared
## rule of DESIGN_SYSTEM.md 4.11, so every screen agrees with the play screen.
static func arrangement_of(node: Control, skin: GameSkin) -> int:
	return Layout.arrangement(content_box(node, skin), skin)


## The skin in use for a node inside a screen: its UiScreen's skin, or Pop
## light outside any screen. Custom drawing reads its colors from this.
static func skin_of(node: Node) -> GameSkin:
	var at: Node = node
	while at != null:
		if at is UiScreen:
			return (at as UiScreen).skin()
		at = at.get_parent()
	return load("res://src/skins/pop_light.tres") as GameSkin


## The hint panel and the full board message slide down from above and fade
## in (Motion PANEL_IN). Shows at once; the motion only follows.
static func panel_in(node: Control) -> void:
	node.visible = true
	if not node.is_inside_tree():
		return
	var skin: GameSkin = skin_of(node)
	var rest: float = node.position.y
	node.modulate.a = 0.0
	node.position.y = rest - skin.space_l
	var tween: Tween = node.create_tween().set_parallel(true)
	tween.tween_property(node, ^"modulate:a", 1.0, Motion.PANEL_IN).set_trans(Motion.trans(&"PANEL_IN")).set_ease(Motion.ease_of(&"PANEL_IN"))
	tween.tween_property(node, ^"position:y", rest, Motion.PANEL_IN).set_trans(Motion.trans(&"PANEL_IN")).set_ease(Motion.ease_of(&"PANEL_IN"))


## Hides the panel at once, so it never takes a tap after it closed. No
## PANEL_OUT motion yet.
static func panel_out(node: Control) -> void:
	if not node.visible:
		return
	node.visible = false
	node.modulate.a = 1.0
