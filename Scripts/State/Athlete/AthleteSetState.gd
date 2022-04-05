extends "res://Scripts/State/AthleteState.gd"

func Enter(athlete:Athlete):
	nameOfState="Set"
	athlete.moveTarget = athlete.team.receptionTarget
	athlete.moveTarget.y = 0
	pass
func Update(athlete:Athlete):
	#$athlete.rotate_x(0.4)
	pass
func Exit(athlete:Athlete):
	pass

func WaitThenDefend(athlete:Athlete, time:float):
	yield(athlete.get_tree().create_timer(time), "timeout")
	
	athlete.stateMachine.SetCurrentState(athlete.defendState)
