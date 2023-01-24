extends "res://Scripts/State/AthleteState.gd"

func Enter(athlete:Athlete):
	nameOfState="Cover"
		
	# just for starters, move half way towards the set target
	if athlete.team.setTarget:
		athlete.moveTarget = (athlete.team.setTarget.target + athlete.translation) /2
		athlete.moveTarget.y = 0
	else:
		print("no set target")
	
func Update(athlete:Athlete):
	athlete.DontFallThroughFloor()
		


func Exit(athlete:Athlete):
	pass
