extends "res://Scripts/State/TeamState.gd"

func Enter(team:Team):
	for i in range(6):
		#	var pos = team.defaultPositions[team.courtPlayers[i].rotationPosition -1]
		team.courtPlayers[i].translation = team.defaultPositions[team.courtPlayers[i].rotationPosition -1] * team.flip + Vector3.UP * .5 * i
	
	team.courtPlayers[team.server].translation = team.flip * Vector3(10,0,-2)
	pass
func Update(team:Team):
	if Input.is_action_just_pressed("ui_accept"):
		pass#team.Rotate()
	pass
func Exit(team:Team):
	pass
