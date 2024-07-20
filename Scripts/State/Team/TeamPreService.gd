extends "res://Scripts/State/Team/TeamState.gd"
class_name TeamPreService

func Enter(team:TeamNode):
	nameOfState = "Pre Service"

#	if team.data.isHuman:
#		print("Human team about to serve ----------------------------")
	team.data.isNextToSpike = false
#	team.CachePlayers()
	for i in range(6):
		#	var pos = team.defaultPositions[team.courtPlayers[i].rotationPosition -1]
		team.courtPlayerNodes[i].position = team.defaultPositions[team.courtPlayerNodes[i].stats.rotationPosition -1] * team.flip
		team.courtPlayerNodes[i].moveTarget = team.courtPlayerNodes[i].position
		team.courtPlayerNodes[i].stateMachine.SetCurrentState(team.courtPlayerNodes[i].chillState)
		team.courtPlayerNodes[i].model.rotation.y = -team.flip * PI/2

	var server:Athlete = team.courtPlayerNodes[team.server]
	if team.data.isHuman:
		Console.AddNewLine(team.data.teamName + " choosing server. Server = " + str(team.server))
		for i in range (6):
			Console.AddNewLine(team.courtPlayerNodes[i].stats.lastName + " " + str(team.courtPlayerNodes[i].stats.rotationPosition))
		Console.AddNewLine(" ")
	server.position = team.flip * Vector3(13,0,-2)
	server.moveTarget = server.position

	team.ball.position = server.position + Vector3.UP + Vector3.LEFT*team.flip/3
	team.ball.sleeping = true
	team.ball.freeze = true

	#server.stateMachine.SetCurrentState(server.serveState)

	team.chosenSetter = null
	team.CheckForLiberoChange()

	if team.data.isHuman:
		team.mManager.teamInfoUI.InitialiseOnCourtPlayerUI()
	else:
		team.mManager.serveUI.HideServeChoice()

	if !team.data.isHuman:
		team.mManager.TESTteamRepresentation.AssignCourtPlayers(team)
		#team.mManager.TESTteamRepresentation.UpdateRepresentation(get_process_delta_time())

	team.middleFront.blockState.isCommitBlocking = true
	team.middleFront.blockState.commitBlockTarget = team.defendState.otherTeam.middleFront

	EnsureBenchInPosition(team)

func EnsureBenchInPosition(team:TeamNode):
	for i in range(team.benchPlayerNodes.size()):
		team.benchPlayerNodes[i].position = Vector3(team.flip * (i + 9), 0, 10)
		team.benchPlayerNodes[i].moveTarget = team.benchPlayerNodes[i].position

func Update(team:TeamNode):
	team.stateMachine.SetCurrentState(team.serveState)
	pass
func Exit(_team:TeamNode):
	pass
