extends "res://Scripts/State/AthleteState.gd"
class_name AthleteFreeBallState
var digHeight:float = 0.5

func Enter(athlete:Athlete):
	nameOfState="FreeBall"
	athlete.animTree.set("parameters/state/transition_request", "digging")
	
func Update(athlete:Athlete):
	athlete.DontFallThroughFloor()
	if athlete.ball.position.distance_to(Vector3(athlete.position.x, digHeight, athlete.position.z)) <= 0.5:
		athlete.ball.attackTarget = Vector3(athlete.team.flip * randf_range(-2,-9), 0, randf_range(-4.5, 4.5))
		athlete.ball.linear_velocity = Maths.CalculateBallOverNetVelocity(athlete.ball.position, athlete.ball.attackTarget, 3.1, 1.0)
		athlete.team.mManager.BallOverNet(athlete.team.isHuman)
		athlete.ball.difficultyOfReception = 1.3

func Exit(_athlete:Athlete):
	pass
