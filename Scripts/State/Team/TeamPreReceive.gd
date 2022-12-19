extends "res://Scripts/State/Team/TeamState.gd"

func Enter(team:Team):
	#ChooseReceiver
	for athlete in team.courtPlayers:
		athlete.translation = team.flip * team.defaultReceiveRotations[team.server][athlete.rotationPosition - 1]
		athlete.moveTarget = team.flip * team.defaultReceiveRotations[team.server][athlete.rotationPosition - 1]
		athlete.stateMachine.SetCurrentState(athlete.chillState)
		athlete.rotation.y = -team.flip*PI/2
		
	if team.outsideFront.rotationPosition == 2 && team.oppositeHitter.rotationPosition == 4:
		team.outsideFront.role = Enums.Role.Opposite
		team.oppositeHitter.role = Enums.Role.Outside
		team.markUndoChangesToRoles = true

	team.isNextToSpike = true
	team.CheckForLiberoChange()
	
func Update(team:Team):
	#Is the ball close enough
	pass
func Exit(team:Team):
	#Discard receiver info?
	pass
