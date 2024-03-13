extends CanvasLayer

@onready var camera = $"/root/MatchScene/Camera3D"
@onready var teamSubstitutionUI:TeamSubstitutionUI = $TeamSubstitutionUI

var mManager:MatchManager

func _ready() -> void:
	$TeamSubstitutionUI/AcceptButton.connect("pressed",Callable(self,"ToggleTeamInfo"))
	mManager = get_tree().root.get_node("MatchScene")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_focus_next"):
		ToggleTeamInfo()

func ToggleTeamInfo():
	teamSubstitutionUI.Refresh()

	$OnCourtPlayers.visible = !$OnCourtPlayers.visible
	
	if visible:
		if mManager.preSet:
			mManager.StartSet()
			
		hide()
		if !camera.enabled: 
			$"/root/MatchScene/Camera3D/".get_child(0).UnlockCamera()
	
	else:
		Console.Clear()
		show()
		if camera.enabled:
			camera.set_enabled(false)
			$"/root/MatchScene/Camera3D/".get_child(0).LockCamera()
			
		
func InitialiseOnCourtPlayerUI():
	for i in range(6):
		var onCourtPlayer = $OnCourtPlayers/VBoxContainer.get_child(i)
		onCourtPlayer.athlete = mManager.teamA.courtPlayers[i]
		onCourtPlayer.UpdateFields()
