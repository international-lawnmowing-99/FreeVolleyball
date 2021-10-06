extends "res://Scripts/State/AthleteState.gd"
var ball
func Enter(athlete:Athlete):
	ball = athlete.team.ball
	athlete.moveTarget = ball.attackTarget

func Update(athlete:Athlete):
	athlete.rotate_y(0.02)
	athlete.timeTillBallReachesMe = Vector3(ball.translation.x, 0, ball.translation.z).distance_to(Vector3(athlete.translation.x, 0, athlete.translation.z))\
				/max(Vector3(ball.linear_velocity.x, 0, ball.linear_velocity.z).length(), 0.001)
				
	#if athlete.timeTillBallReachesMe 
	if ball.translation.y < 1 && \
		(Vector3(ball.translation.x,0, ball.translation.z)).distance_to(athlete.translation) < 1:
		#if ball.translation.distance_to(athlete.translation) < 1:
			PassBall(athlete)
	pass
func Exit(athlete:Athlete):
	pass
func PassBall(athlete):
	#Engine.time_scale = 0.25
#	emit_signal("ballPassed")
	
	ball.linear_velocity = Vector3.ZERO
	ball.gravity_scale = 1
	
	var receptionTarget = Vector3(athlete.team.flip * 0.5, 2.5, 0)
	
	#Bizzare physics hack needed
	ball.linear_velocity = (ball.FindWellBehavedParabola(ball.transform.origin, receptionTarget, rand_range(3,7)))
	yield(athlete.get_tree(),"idle_frame")
	ball.linear_velocity = (ball.FindWellBehavedParabola(ball.transform.origin, receptionTarget, rand_range(3,7)))
