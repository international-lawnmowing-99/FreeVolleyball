extends "res://Scripts/State/Team/TeamState.gd"

func Enter(team:Team):
	nameOfState = "Pre Service"
	
#	if team.isHuman:
#		print("Human team about to serve ----------------------------")
	team.isNextToSpike = false
	
	for i in range(6):
		#	var pos = team.defaultPositions[team.courtPlayers[i].rotationPosition -1]
		team.courtPlayers[i].position = team.defaultPositions[team.courtPlayers[i].rotationPosition -1] * team.flip 
		team.courtPlayers[i].moveTarget = team.courtPlayers[i].position
		team.courtPlayers[i].stateMachine.SetCurrentState(team.courtPlayers[i].chillState)
		team.courtPlayers[i].rotation.y = -team.flip*PI/2
		
	var server:Athlete = team.courtPlayers[team.server]
#	if team.isHuman:
#		print (team.teamName + " choosing server. Server = " + str(team.server))
#		for i in range (6):
#			print (team.courtPlayers[i].stats.lastName + " " + str(team.courtPlayers[i].rotationPosition))
#		print(" ")
	server.position = team.flip * Vector3(13,0,-2)
	server.moveTarget = server.position
	
	team.ball.position = server.position + Vector3.UP + Vector3.LEFT*team.flip/3
	team.ball.sleeping = true
	team.ball.freeze = true
	
	server.stateMachine.SetCurrentState(server.serveState)
	
	team.chosenSetter = null
	
	if team.isHuman:
		team.mManager.teamInfoUI.InitialiseOnCourtPlayerUI()
	else: 
		team.mManager.serveUI.HideServeChoice()

func Update(team:Team):
	team.stateMachine.SetCurrentState(team.serveState)
	pass
func Exit(_team:Team):
	pass
