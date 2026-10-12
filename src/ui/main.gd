extends Control
## The main scene (scenes/ui/main.tscn): the host every screen goes into.
## It hands itself to the App autoload, which opens the first screen.
## Owner: ui-systems-dev.


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var app: AppService = get_node_or_null(^"/root/App") as AppService
	if app == null:
		push_error("Main: the App autoload (res://src/ui/app.gd) is not registered")
		return
	app.attach_host(self)
