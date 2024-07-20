extends CanvasLayer

class_name TeamInfoUI

@onready var camera = $"/root/MatchScene/Camera3D"
@onready var teamSubstitutionUI:TeamSubstitutionUI = $TeamSubstitutionUI
@onready var onCourPlayers = $OnCourtPlayers
var mManager:MatchManager

func _ready() -> void:
	$TeamSubstitutionUI/AcceptButton.connect("pressed",Callable(self,"ToggleTeamInfo"))
	mManager = get_tree().root.get_node("MatchScene")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_focus_next"):
		ToggleTeamInfo()

func ToggleTeamInfo():
	teamSubstitutionUI.Refresh()

	if teamSubstitutionUI.visible:
		if mManager.preSet:
			mManager.StartSet()

		teamSubstitutionUI.hide()
		onCourPlayers.visible = true
		if !camera.enabled:
			$"/root/MatchScene/Camera3D/".get_child(0).UnlockCamera()

	else:
		Console.Clear()
		teamSubstitutionUI.show()
		onCourPlayers.visible = false
		if camera.enabled:
			camera.set_enabled(false)
			$"/root/MatchScene/Camera3D/".get_child(0).LockCamera()


func InitialiseOnCourtPlayerUI():
	for i in range(6):
		var onCourtPlayer = $OnCourtPlayers/VBoxContainer.get_child(i)
		if mManager.teamA.courtPlayerNodes[i] == mManager.teamA.libero || \
			mManager.teamA.courtPlayerNodes[i] == mManager.teamA.libero2:
				onCourtPlayer.athlete = mManager.teamA.playerCurrentlyLiberoedOff
		else:
			onCourtPlayer.athlete = mManager.teamA.courtPlayerNodes[i]

		onCourtPlayer.UpdateFields()

	$OnCourtPlayers/VBoxContainer/OnCourtPlayer7.athlete = mManager.teamA.activeLibero
	$OnCourtPlayers/VBoxContainer/OnCourtPlayer7.UpdateFields()
