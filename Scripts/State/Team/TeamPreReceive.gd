extends "res://Scripts/State/Team/TeamState.gd" 
class_name TeamPreReceive

func Enter(team:Team):
	nameOfState = "Pre Receive"
	#ChooseReceiver
	for athlete in team.courtPlayers:
		athlete.position = team.flip * team.receiveRotations[team.server][athlete.rotationPosition - 1]
		athlete.moveTarget = team.flip * team.receiveRotations[team.server][athlete.rotationPosition - 1]
		athlete.stateMachine.SetCurrentState(athlete.chillState)
		athlete.animTree.set("parameters/state/transition_request", "digging")
		athlete.rotation.y = -team.flip*PI/2
		
	if !team.outsideFront || !team.oppositeHitter:
		#It's happened again...
		pass
	if team.outsideFront.rotationPosition == 2 && team.oppositeHitter.rotationPosition == 4:
		team.outsideFront.role = Enums.Role.Opposite
		team.oppositeHitter.role = Enums.Role.Outside
		team.markUndoChangesToRoles = true

	team.isNextToSpike = true
	team.CheckForLiberoChange()
	team.chosenSetter = null
	
	if !team.isHuman:
		team.mManager.TESTteamRepresentation.AssignCourtPlayers(team)
		team.mManager.TESTteamRepresentation.UpdateRepresentation(get_process_delta_time())
	
func Update(_team:Team):
	#Is the ball close enough
	pass
func Exit(_team:Team):
	#Discard receiver info?
	pass
