extends "res://Scripts/State/Team/TeamState.gd"


func Enter(team:Team):
	for player in team.courtPlayers:
		if !player.FrontCourt():
			if player.rb.mode == RigidBody.MODE_KINEMATIC:
				player.stateMachine.SetCurrentState(player.defendState)
		else:
			player.stateMachine.SetCurrentState(player.blockState)
	pass
func Update(team:Team):
	pass
func Exit(team:Team):
	pass
