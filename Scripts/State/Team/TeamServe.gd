extends "res://Scripts/State/Team/TeamState.gd"

func Enter(team:Team):
	.Enter(team)
	
	
	
	pass
func Update(team:Team):
	if team.ball.get_parent():
		# Reparenting just doesn't work yet, come back in 4.0
		pass
func Exit(team:Team):
	pass
