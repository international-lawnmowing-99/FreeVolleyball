extends "res://Scripts/State/AthleteState.gd"

var ball
var timeTillBallReachesMe

func Enter(athlete:Athlete):
	nameOfState="pass"
	ball = athlete.team.ball
	var servePos = ball.translation
	athlete.moveTarget = ball.BallPositionAtGivenHeight(0.9) + Vector3(0,-.9, rand_range(-.5,.51))
	athlete.moveTarget += (athlete.moveTarget - Vector3(servePos.x, 0, servePos.z)).normalized()/2
	#look_at(Vector3(servePos.x,0, servePos.z), Vector3.UP)
	
	#point where a circle will intersect with the xz vector of the ball's motion
	#circle is (x-h)^2 + (y-k)^2 = r^2
	var h = athlete.translation.x
	var k = athlete.translation.z
	var r = .66 #Dig radius is this much?
	#line is ...
	var xPart = ball.linear_velocity.x
	var zPart = ball.linear_velocity.z # (It's y!)
	
	var m
	if xPart == 0 && zPart == 0:
		pass
		#print("no vel to work with")
	elif zPart == 0:
		m = 0
		#print("m = 0")
	elif xPart == 0:
		m = 999999
		#print("m = big")
	else:
		m = zPart/xPart 
	#y=mx+b
	#b = y - mx
	var b = servePos.z - m * servePos.x
	
	#Will the two meet??
	# circle = line 
	
	var aDet = m*m + 1
	var bDet = -2*h + 2*m*b - 2*k*m
	var cDet = h*h + b*b + k*k -2*k*b - r*r
	
	var determinate = bDet * bDet - 4 *aDet * cDet
	
	var intersectionPointX
	
	if determinate == 0:
		#Congrats, you have a tangent
		intersectionPointX = (-bDet + sqrt(determinate))/(2*aDet)
	elif determinate > 0:
		# Choose t
		var point1x =  (-bDet + sqrt(determinate))/(2*aDet)
		var point2x = (-bDet - sqrt(determinate))/(2*aDet)
		intersectionPointX = max(point1x, point2x)
	else:
		# No intersections
		intersectionPointX = h +1
		#print("can't make that work chap")
		
	var intersectionPointZ = m*intersectionPointX + b
	
	
	athlete.digAngle = rad2deg(ball.SignedAngle(athlete.transform.basis.z, -athlete.translation + Vector3(intersectionPointX,0,intersectionPointZ), Vector3.UP))

	athlete.anglewanted = -athlete.translation + Vector3(intersectionPointX,0,intersectionPointZ)


func Update(athlete:Athlete):

	athlete.timeTillBallReachesMe = Vector3(ball.translation.x, 0, ball.translation.z).distance_to(Vector3(athlete.translation.x, 0, athlete.translation.z))\
				/max(Vector3(ball.linear_velocity.x, 0, ball.linear_velocity.z).length(), 0.001)
				
	if athlete.timeTillBallReachesMe <1.3:
		var animFactor = 1.3-  athlete.timeTillBallReachesMe 
		athlete.animTree.set("parameters/BlendSpace1D/blend_position", animFactor)
		athlete.RotateDigPlatform(lerp(0,athlete.digAngle,(min(1,1/athlete.timeTillBallReachesMe - 2))))
	#else:
		#var a = athlete.animTree.get("parameters/BlendSpace1D/blend_position")
		#athlete.animTree.set("parameters/BlendSpace1D/blend_position", lerp(a, 0, 5*athlete.myDelta))
		#athlete.digAngle = lerp(athlete.digAngle,0,3*athlete.myDelta)
		#athlete.RotateDigPlatform(athlete.digAngle)
	if ball.translation.y < 1 && \
		(Vector3(ball.translation.x,0, ball.translation.z)).distance_to(athlete.translation) < 1:
			PassBall(athlete)
			
func Exit(athlete:Athlete):
	pass
	
func PassBall(athlete):
	#Engine.time_scale = 0.25
#	emit_signal("ballPassed")
	
	ball.linear_velocity = Vector3.ZERO
	ball.gravity_scale = 1
	
	var receptionTarget = Vector3(athlete.team.flip * 0.5, 2.5, 0)
	athlete.team.receptionTarget = receptionTarget
	
	#Bizzare physics hack needed
	ball.linear_velocity = (ball.FindWellBehavedParabola(ball.transform.origin, receptionTarget, rand_range(4,8)))
	yield(athlete.get_tree(),"idle_frame")
	ball.linear_velocity = (ball.FindWellBehavedParabola(ball.transform.origin, receptionTarget, rand_range(4,8)))

	athlete.get_tree().get_root().get_node("MatchScene").BallReceived(athlete.team.isHuman)

	yield(athlete.get_tree().create_timer(.5), "timeout")
	athlete.stateMachine.SetCurrentState(athlete.transitionState)