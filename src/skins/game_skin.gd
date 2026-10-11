class_name GameSkin extends Resource
## One built-in skin: its identity, then every color and size the game draws
## with. The tokens are the rows of the "Skin tokens" table in
## docs/DESIGN_SYSTEM.md section 1, with the same names, types, order and
## groups. Values live in src/skins/pop_light.tres and src/skins/pop_dark.tres.
## Sizes are dp, shares or degrees as the table says.

@export var id: StringName
@export var display_name: String
@export var is_dark: bool

@export_group("Page, surfaces and text")
@export var page_bg: Color
@export var surface_bg: Color
@export var surface_alt_bg: Color
@export var outline: Color
@export var shadow: Color
@export var scrim: Color
@export var text: Color
@export var text_muted: Color
@export var text_accent: Color

@export_group("Stickers, tags and charts")
@export var sticker_bg: Color
@export var sticker_text: Color
@export var celebrate_bg: Color
@export var celebrate_text: Color
@export var hint_tag_bg: Color
@export var hint_tag_text: Color
@export var chart_bar: Color

@export_group("HUD")
@export var hud_bg: Color
@export var hud_text: Color
@export var hud_label: Color
@export var hud_score_bg: Color
@export var hud_score_text: Color

@export_group("Buttons")
@export var button_bg: Color
@export var button_text: Color
@export var button_primary_bg: Color
@export var button_primary_text: Color
@export var button_danger_bg: Color
@export var button_danger_text: Color
@export var button_disabled_bg: Color
@export var button_disabled_text: Color
@export var button_disabled_outline: Color
@export var button_disabled_hatch: Color

@export_group("Number pad, mode toggle and switch")
@export var pad_key_place_bg: Color
@export var pad_key_place_text: Color
@export var pad_key_cross_bg: Color
@export var pad_key_cross_text: Color
@export var pad_key_cross_mark: Color
@export var mode_toggle_bg: Color
@export var mode_toggle_text: Color
@export var mode_toggle_active_bg: Color
@export var mode_toggle_active_text: Color
@export var switch_on_bg: Color
@export var switch_off_bg: Color
@export var switch_knob: Color

@export_group("Board: frame, lines and cell fills")
@export var board_bg: Color
@export var line_cell: Color
@export var line_box: Color
@export var line_outer: Color
@export var cell_bg: Color
@export var cell_selected_bg: Color
@export var cell_peer_bg: Color
@export var cell_same_digit_bg: Color
@export var cell_conflict_bg: Color
@export var cell_hint_target_bg: Color
@export var cell_hint_reason_bg: Color

@export_group("Board: digits, candidates and marks")
@export var digit_given: Color
@export var digit_placed: Color
@export var digit_conflict: Color
@export var candidate_open: Color
@export var candidate_crossed: Color
@export var cross_mark_hand: Color
@export var cross_mark_auto: Color
@export var selection_frame_place: Color
@export var selection_frame_cross: Color
@export var hint_target_mark: Color
@export var hint_reason_mark: Color
@export var conflict_mark: Color

@export_group("Board shape")
@export var line_cell_w: float
@export var line_box_w: float
@export var line_outer_w: float
@export var board_radius: float
@export var ring_inset: float
@export var candidate_gap: float
@export var digit_size: float
@export var given_embolden: float
@export var placed_embolden: float
@export var candidate_embolden: float
@export var cross_mark_span: float
@export var cross_mark_w: float
@export var knockout_w: float
@export var selection_frame_w: float
@export var selection_gap: float
@export var selection_mid_dash: float
@export var hint_mark_w: float
@export var hint_bracket_len: float
@export var hint_tick_len: float
@export var conflict_bar_w: float
@export var conflict_bar_len: float
@export var conflict_bar_y: float

@export_group("UI shape and spacing")
@export var outline_w: float
@export var shadow_offset: float
@export var radius_control: float
@export var radius_card: float
@export var sticker_tilt: float
@export var celebrate_tilt: float
@export var hatch_w: float
@export var hatch_gap: float
@export var page_margin: float
@export var space_xs: float
@export var space_s: float
@export var space_m: float
@export var space_l: float
@export var space_xl: float
@export var group_gap: float
