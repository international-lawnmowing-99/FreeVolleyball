extends "res://Scripts/State/AthleteState.gd"
class_name AthleteDefendState
const Enums = preload("res://Scripts/World/Enums.gd")

func Enter(athlete:Athlete):
	nameOfState="Defend"
	athlete.animTree.set("parameters/state/transition_request", "digging")
	match athlete.role:
		Enums.Role.Setter:
			athlete.moveTarget = athlete.team.flip *  Vector3(5.5,0,-4)
		Enums.Role.Outside:
			athlete.moveTarget = athlete.team.flip * Vector3(8, 0, 0)
		Enums.Role.Opposite:
			athlete.moveTarget = athlete.team.flip * Vector3(5.5, 0, -4)
		Enums.Role.Middle:
			athlete.moveTarget = athlete.team.flip * Vector3(5.5, 0, 4)
		Enums.Role.Libero:
			athlete.moveTarget = athlete.team.flip * Vector3(5.5, 0, 4)

func Update(athlete:Athlete):
	athlete.DontFallThroughFloor()

func Exit(_athlete:Athlete):
	pass
