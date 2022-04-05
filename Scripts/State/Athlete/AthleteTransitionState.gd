extends "res://Scripts/State/AthleteState.gd"



func Enter(athlete:Athlete):
	nameOfState="transition"
	athlete.moveTarget = athlete.team.GetTransitionPosition(athlete)
	pass
func Update(athlete:Athlete):
	if athlete.translation.distance_squared_to(athlete.moveTarget) < 0.1:
		if athlete == athlete.team.libero || athlete == athlete.team.middleBack:
			pass
		else:
			athlete.stateMachine.SetCurrentState(athlete.spikeState)
	pass
func Exit(athlete:Athlete):
	pass
