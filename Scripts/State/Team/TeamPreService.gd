extends "res://Scripts/State/Team/TeamState.gd"

func Enter(team:Team):
	for i in range(6):
		#	var pos = team.defaultPositions[team.courtPlayers[i].rotationPosition -1]
		team.courtPlayers[i].translation = team.defaultPositions[team.courtPlayers[i].rotationPosition -1] * team.flip 
		team.courtPlayers[i].moveTarget = team.courtPlayers[i].translation
		team.courtPlayers[i].stateMachine.SetCurrentState(team.courtPlayers[i].chillState)
	var server:Athlete = team.courtPlayers[team.server]
	server.translation = team.flip * Vector3(10,0,-2)
	team.ball.translation = server.translation + Vector3.UP + Vector3.LEFT*team.flip/3
	team.ball.sleeping = true
	team.ball.mode= RigidBody.MODE_STATIC
	
	server.stateMachine.SetCurrentState(server.serveState)
	
	pass
func Update(team:Team):
	team.stateMachine.SetCurrentState(team.serveState)
	pass
func Exit(team:Team):
	pass
