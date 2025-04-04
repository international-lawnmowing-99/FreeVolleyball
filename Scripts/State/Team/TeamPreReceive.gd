extends "res://Scripts/State/Team/TeamState.gd"
class_name TeamPreReceive

func Enter(team:TeamNode):
	nameOfState = "Pre Receive"
	#ChooseReceiver
	for athlete in team.courtPlayerNodes:
		athlete.position = team.flip * team.receiveRotations[team.server][athlete.stats.rotationPosition - 1]
		athlete.moveTarget = team.flip * team.receiveRotations[team.server][athlete.stats.rotationPosition - 1]
		athlete.stateMachine.SetCurrentState(athlete.chillState)
		athlete.animTree.set("parameters/state/transition_request", "digging")
		athlete.model.rotation.y = -team.flip*PI/2



	if !team.outsideFront || !team.oppositeHitter:
		#It's happened again...
		# are the two teams the same?? hence 24 players - YES!
		var i
		pass
	if team.outsideFront.stats.rotationPosition == 2 && team.oppositeHitter.stats.rotationPosition == 4:
		team.outsideFront.stats.role = Enums.Role.Opposite
		team.oppositeHitter.stats.role = Enums.Role.Outside
		team.data.markUndoChangesToRoles = true

	team.data.isNextToSpike = true
	team.CheckForLiberoChange()
	team.chosenSetter = null

	if !team.data.isHuman:
		team.mManager.TESTteamRepresentation.AssignCourtPlayers(team)
		#team.mManager.TESTteamRepresentation.UpdateRepresentation(get_process_delta_time())

#	team.CachePlayers()

func Update(_team:TeamNode):
	#Is the ball close enough
	pass
func Exit(_team:TeamNode):
	#Discard receiver info?
	pass
