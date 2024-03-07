extends CanvasLayer

@onready var controlNode = $TeamSubstitutionUI
@onready var camera = $"/root/MatchScene/Camera3D"

var mManager:MatchManager

func _ready() -> void:
	$TeamSubstitutionUI/TeamSubstitutionUI/AcceptButton.connect("pressed",Callable(self,"ToggleTeamInfo"))
	mManager = get_tree().root.get_node("MatchScene")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_focus_next"):
		ToggleTeamInfo()

func ToggleTeamInfo():
	if mManager.preSet:
		mManager.StartSet()
	$TeamSubstitutionUI/TeamSubstitutionUI.Refresh()

	$OnCourtPlayers.visible = !$OnCourtPlayers.visible
	
	if controlNode.visible:
		controlNode.visible = false
		if !camera.enabled: 
			$"/root/MatchScene/Camera3D/".get_child(0).UnlockCamera()
	
	else:
		Console.Clear()
		controlNode.visible = true
		if camera.enabled:
			camera.set_enabled(false)
			$"/root/MatchScene/Camera3D/".get_child(0).LockCamera()
			
		
func InitialiseOnCourtPlayerUI():
	for i in range(6):
		var onCourtPlayer = $OnCourtPlayers/VBoxContainer.get_child(i)
		onCourtPlayer.athlete = mManager.teamA.courtPlayers[i]
		onCourtPlayer.UpdateFields()
