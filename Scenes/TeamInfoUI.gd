extends CanvasLayer

func _ready() -> void:
	$Control/TeamSelectionUI/AcceptButton.connect("pressed", self, "ToggleTeamInfo")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_focus_next"):
		ToggleTeamInfo()

func ToggleTeamInfo():
	$Control.visible = !$Control.visible
	$Control/TeamSelectionUI.Refresh()
