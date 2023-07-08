extends "res://Scripts/State/AthleteState.gd"
class_name AthleteCoverState

func Enter(athlete:Athlete):
	nameOfState="Cover"
		
	# just for starters, move half way towards the set target
	if athlete.team.setTarget:
		athlete.moveTarget = (athlete.team.setTarget.target + athlete.position) /2
		athlete.moveTarget.y = 0
		if athlete.team.isHuman:
			athlete.moveTarget.x = max(athlete.moveTarget.x, 0.5)
		else:
			athlete.moveTarget.x = min(athlete.moveTarget.x, -0.5)
	else:
		pass
#		print("no set target")
	
func Update(athlete:Athlete):
	athlete.DontFallThroughFloor()
		


func Exit(_athlete:Athlete):
	pass
