extends Node
## Autoload "Audio". Plays the click. Depends on nothing else in src/.
##
## The click is built once when the service is created. play_click only
## restarts a voice on one player, so fast taps never allocate. At most
## MAX_VOICES clicks sound at once; a new tap takes over the oldest voice,
## so rapid taps never stack into a loud burst.

const MAX_VOICES: int = 2

## App sets this from Settings.sound. On by default.
var enabled: bool = true

var _player: AudioStreamPlayer = null
## Clicks asked for while sound was on. Lets headless tests see that the
## toggle gates play_click, since the test runner has no live scene tree.
var _click_requests: int = 0


func _init() -> void:
	_player = AudioStreamPlayer.new()
	_player.name = "ClickPlayer"
	_player.stream = ClickSynth.build()
	_player.max_polyphony = MAX_VOICES
	add_child(_player)


## Does nothing when sound is off or the service is not in the scene tree.
func play_click() -> void:
	if not enabled:
		return
	_click_requests += 1
	# AudioStreamPlayer.play errors outside the tree, so skip it there.
	if not is_inside_tree():
		return
	_player.play()
