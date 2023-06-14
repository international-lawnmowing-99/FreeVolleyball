extends "res://Scripts/State/AthleteState.gd"
class_name AthleteTransitionState


func Enter(athlete:Athlete):
	nameOfState="transition"
	athlete.moveTarget = athlete.team.GetTransitionPosition(athlete)
	athlete.spikeState.runupStartPosition = athlete.moveTarget
	athlete.animTree.set("parameters/state/transition_request", "moving")
	pass
func Update(athlete:Athlete):
	if athlete.position.distance_squared_to(athlete.moveTarget) < 0.1\
	&& athlete.rb.freeze:
		if athlete == athlete.team.libero || athlete == athlete.team.middleBack:
			pass
		else:
			if athlete == athlete.team.chosenSetter:
				athlete.stateMachine.SetCurrentState(athlete.setState)
			else:
				athlete.stateMachine.SetCurrentState(athlete.spikeState)
	pass
func Exit(_athlete:Athlete):
	pass

func CanFullyTransition(_athlete) -> bool:
	return true
