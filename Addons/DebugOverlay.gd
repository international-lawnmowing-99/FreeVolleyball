extends CanvasLayer

#onready var draw =  $"/root/MatchScene/DebugOverlay/DebugDraw3D"

func _ready():
	if not InputMap.has_action("toggle_debug"):
		InputMap.add_action("toggle_debug")
		var ev = InputEventKey.new()
		ev.keycode = KEY_BACKSLASH
		InputMap.action_add_event("toggle_debug", ev)

func _input(event):
	if event.is_action_pressed("toggle_debug"):
		for n in get_children():
			n.visible = not n.visible
