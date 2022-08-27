extends CanvasLayer

onready var controlNode = $Control
onready var camera = $"/root/MatchScene/Camera"

func _ready() -> void:
	$Control/TeamSelectionUI/AcceptButton.connect("pressed", self, "ToggleTeamInfo")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_focus_next"):
		ToggleTeamInfo()

func ToggleTeamInfo():
	$Control/TeamSelectionUI.Refresh()
	
	if controlNode.visible:
		controlNode.visible = false
		if !camera.enabled: 
			$"/root/MatchScene/Camera/".get_child(0).UnlockCamera()
	
	else:
		Console.Clear()
		controlNode.visible = true
		if camera.enabled:
			camera.set_enabled(false)
			$"/root/MatchScene/Camera/".get_child(0).LockCamera()
		
