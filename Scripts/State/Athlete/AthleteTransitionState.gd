extends "res://Scripts/State/AthleteState.gd"
class_name AthleteTransitionState


func Enter(athlete:Athlete):
	nameOfState="transition"
	if !athlete.setRequest:
		athlete.moveTarget = athlete.team.GetTransitionPosition(athlete)
#		Console.AddNewLine(athlete.stats.lastName + " failed to transition adequately, no set target yet...", Color.AZURE)
	else:
		athlete.moveTarget = Maths.XZVector(athlete.setRequest.target) + athlete.team.flip * Vector3(3 + athlete.stats.verticalJump/2, 0, 0)
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

#func CanFullyTransition(_athlete) -> bool:
#	return true
