extends CanvasLayer

onready var controlNode = $TeamSelectionUI
onready var camera = $"/root/MatchScene/Camera"
var mManager:MatchManager

func _ready() -> void:
	$TeamSelectionUI/TeamSelectionUI/AcceptButton.connect("pressed", self, "ToggleTeamInfo")
	mManager = get_tree().root.get_node("MatchScene")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_focus_next"):
		ToggleTeamInfo()

func ToggleTeamInfo():
	$TeamSelectionUI/TeamSelectionUI.Refresh()

	$OnCourtPlayers.visible = !$OnCourtPlayers.visible
	
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
			
		
func InitialiseOnCourtPlayerUI():
	for i in range(7):
		var onCourtPlayer = $OnCourtPlayers/VBoxContainer.get_child(i)
		onCourtPlayer.athlete = mManager.teamA.allPlayers[i]
		onCourtPlayer.UpdateFields()
