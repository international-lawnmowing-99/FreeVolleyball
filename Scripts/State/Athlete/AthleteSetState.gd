extends "res://Scripts/State/AthleteState.gd"

var hasSet:bool = false
var interpolationSpeed = 5
func Enter(athlete:Athlete):
	nameOfState="Set"
	athlete.moveTarget = athlete.team.receptionTarget
	athlete.moveTarget.y = 0
	athlete.leftIK.start()
	athlete.rightIK.start()
	athlete.leftIK.interpolation = 0
	athlete.rightIK.interpolation = 0
	
	pass
func Update(athlete:Athlete):
#	var ballDistance = athlete.translation.distance_to(athlete.ball.translation)
#	var ballXZVel = Vector2(athlete.ball.linear_velocity.x, athlete.ball.linear_velocity.z).length()
	var timeTillSet = athlete.ball.TimeTillBallReachesHeight(athlete.stats.setHeight)
	athlete.leftIKTarget.global_transform.origin = lerp (athlete.leftIKTarget.global_transform.origin, athlete.ball.translation, athlete.myDelta * interpolationSpeed)
	athlete.rightIKTarget.global_transform.origin = lerp (athlete.rightIKTarget.global_transform.origin, athlete.ball.translation, athlete.myDelta * interpolationSpeed)
	athlete.leftIK.interpolation = lerp(athlete.leftIK.interpolation, (1 - timeTillSet), athlete.myDelta * interpolationSpeed)
	athlete.rightIK.interpolation = lerp(athlete.rightIK.interpolation, (1 - timeTillSet), athlete.myDelta * interpolationSpeed)
	#$athlete.rotate_x(0.4)
	pass
func Exit(athlete:Athlete):
	athlete.leftIK.stop()
	athlete.rightIK.stop()
	pass

func WaitThenDefend(athlete:Athlete, time:float):
	yield(athlete.get_tree().create_timer(time), "timeout")
	
	athlete.stateMachine.SetCurrentState(athlete.defendState)
