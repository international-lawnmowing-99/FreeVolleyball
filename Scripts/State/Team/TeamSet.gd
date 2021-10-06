extends "res://Scripts/State/Team/TeamState.gd"

func Enter(team:Team):
	#ChooseSetter
	pass
func Update(team:Team):
	#Is the ball close enough
	CheckForSpikeDistance(team)
	pass
func Exit(team:Team):
	pass


func CheckForSpikeDistance(team:Team):
	if !team.chosenSpiker:
		print("Error inbound")
		#Log(setTarget.target)
	if team.ball.translation.y <= team.setTarget.y \
	&& abs(team.ball.translation.z) >= abs(team.setTarget.z) && team.ball.linear_velocity.y <= 0:
		team.stateMachine.SetCurrentState(team.spikeState)
