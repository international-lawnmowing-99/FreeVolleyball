extends "res://Scripts/State/AthleteState.gd"
const Enums = preload("res://Scripts/World/Enums.gd")

var ball:Ball
#var timeTillBallReachesMe
var isBallAlreadyPassed:bool = false

var intersectionPointX
var intersectionPointZ

func Enter(athlete:Athlete):
	isBallAlreadyPassed = false
	nameOfState="pass"
	ball = athlete.team.ball
	
	#Make a determination as to whether the ball will land in the court
	#Ideally take into account:
	# 1: confidence that it's in
	# 2: confidence that it's my ball to take
	
	if athlete.team.isHuman:
		if ball.attackTarget.x > 9.2 || ball.attackTarget.x < 0 ||\
		ball.attackTarget.z < -4.7 || ball.attackTarget.z > 4.7:
			athlete.stateMachine.SetCurrentState(athlete.chillState)
			return
	else: 
		if ball.attackTarget.x < -9.2 || ball.attackTarget.x > 0 ||\
		ball.attackTarget.z < -4.7 || ball.attackTarget.z > 4.7:
			athlete.stateMachine.SetCurrentState(athlete.chillState)
			return

	
	var servePos = ball.translation
	athlete.moveTarget = ball.BallPositionAtGivenHeight(0.9) + Vector3(0,-.9, rand_range(-.5,.51))
	athlete.moveTarget += (athlete.moveTarget - Vector3(servePos.x, 0, servePos.z)).normalized()/2
	#look_at(Vector3(servePos.x,0, servePos.z), Vector3.UP)
	
	#point where a circle will intersect with the xz vector of the ball's motion
	#circle is (x-h)^2 + (y-k)^2 = r^2
	var h = athlete.moveTarget.x
	var k = athlete.moveTarget.z
	var r = .66 #Dig radius is this much?
	#line is ...
	var xPart = ball.linear_velocity.x
	var zPart = ball.linear_velocity.z # (It's y!)
	
	var m
	if xPart == 0 && zPart == 0:
		print("no vel to work with")
		m = 9999
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
	
	
	
	if determinate == 0:
		#Congrats, you have a tangent
		intersectionPointX = (-bDet + sqrt(determinate))/(2*aDet)
	elif determinate > 0:
		# Choose t
		var point1x =  (-bDet + sqrt(determinate))/(2*aDet)
		var point2x = (-bDet - sqrt(determinate))/(2*aDet)
		if athlete.team.isHuman:
			intersectionPointX = min(point1x, point2x)
		else:
			intersectionPointX = max(point1x, point2x)
	else:
		# No intersections
		intersectionPointX = h +1
		#print("can't make that work chap")
		
	intersectionPointZ = m*intersectionPointX + b
	
	
	athlete.digAngle = rad2deg(ball.SignedAngle(athlete.transform.basis.z , -athlete.translation + Vector3(intersectionPointX,0,intersectionPointZ), Vector3.UP))
	#other team is rotated -90, we're 90
	#var angle = atan2(athlete.translation.z - intersectionPointZ, athlete.translation.x - intersectionPointX) 
	
	print(str(rad2deg(athlete.transform.basis.z[0])))

	#athlete.anglewanted = -athlete.translation + Vector3(intersectionPointX,0,intersectionPointZ)


func Update(athlete:Athlete):
	athlete.get_node("Debug").global_transform.origin = Vector3(intersectionPointX, .5, intersectionPointZ)
	athlete.timeTillBallReachesMe = Vector3(ball.translation.x, 0, ball.translation.z).distance_to(Vector3(athlete.translation.x, 0, athlete.translation.z))\
				/max(Vector3(ball.linear_velocity.x, 0, ball.linear_velocity.z).length(), 0.001)
				

	if athlete.timeTillBallReachesMe <1.5:
		athlete.animTree.set("parameters/state/current", 1)
		var animFactor = 1.5-  athlete.timeTillBallReachesMe 
		athlete.animTree.set("parameters/Dig/blend_amount", animFactor)

		athlete.RotateDigPlatform(athlete.digAngle)#( lerp(0,athlete.digAngle,(max(1,1/athlete.timeTillBallReachesMe)))))
	#else:
		#var a = athlete.animTree.get("parameters/BlendSpace1D/blend_position")
		#athlete.animTree.set("parameters/BlendSpace1D/blend_position", lerp(a, 0, 5*athlete.myDelta))
		#athlete.digAngle = lerp(athlete.digAngle,0,3*athlete.myDelta)
		#athlete.RotateDigPlatform(athlete.digAngle)
	if !isBallAlreadyPassed && ball.inPlay && ball.translation.y < 1 && \
		(Vector3(ball.translation.x,0, ball.translation.z)).distance_to(athlete.translation) < 1:
			PassBall(athlete)
			
func Exit(athlete:Athlete):
	athlete.animTree.set("parameters/state/current", 0)
	pass
	
func PassBall(athlete:Athlete):
	isBallAlreadyPassed = true
	ball.floating = false
	ball.floatDisplacement = Vector3.ZERO
	#Engine.time_scale = 0.25
	var receptionTarget
	#perfect pass, 2-pass, 1-pass, shank, some sort of unSafety ball that hits the floor near your feet
	var passRoll = rand_range(0, athlete.stats.reception)
	Console.AddNewLine("PASSING || PASS ROLL: " + str(int(passRoll)) + " Difficulty: " + str(int(ball.difficultyOfReception)))
	var rollOffDifference = passRoll - ball.difficultyOfReception
	Console.AddNewLine( str(int(passRoll)) + " out of a possible " + str(int(athlete.stats.reception)), Color.aqua)
	Console.AddNewLine( str(int(rollOffDifference)) + " roll off differece ", Color.red)

	
	if rollOffDifference >= 10:
		# what is the ideal height for the setter to jump set??
		if athlete.role == Enums.Role.Setter:
			if athlete.team.isLiberoOnCourt:
				receptionTarget = Vector3(athlete.team.flip * 3.13, athlete.team.libero.stats.setHeight, 0)
			else:
				receptionTarget = Vector3(athlete.team.flip * 3.13, athlete.team.middleBack.stats.setHeight, 0)
		else:
			receptionTarget = Vector3(athlete.team.flip * 0.5, athlete.team.setter.stats.setHeight, 0)
		Console.AddNewLine(athlete.stats.lastName + " FUCKING MINT pass")
	elif rollOffDifference >= -10:
		receptionTarget = Vector3(athlete.team.flip * rand_range(0.5, 1.5), 2.5, rand_range(-2, 2))
		Console.AddNewLine(athlete.stats.lastName + " 2-point pass")
		pass
	elif rollOffDifference >= -50:
		receptionTarget = Vector3(athlete.translation.x + rand_range(-3,3), 2.4, athlete.translation.z + rand_range(-3,3))
		
		#prevent the setter chasing overpasses... by removing them! (for now)
		if athlete.team.isHuman:
			receptionTarget.x = max(receptionTarget.x, 0.1)
		else:
			receptionTarget.x = min(receptionTarget.x, -0.1)
		######################################################################
		
		Console.AddNewLine(athlete.stats.lastName + " 1-point pass")
		pass	
	else:
		ball.linear_velocity.y *= -1

		
		if ball.BallMaxHeight() >= 2.4:
			receptionTarget = ball.BallPositionAtGivenHeight(2.5)
		else:
			receptionTarget = ball.BallPositionAtGivenHeight(0)

		Console.AddNewLine(athlete.stats.lastName + " - Shit pass mate")
		pass	



	ball.gravity_scale = 1
	ball.angular_velocity += Vector3 ( rand_range(-5,5),rand_range(-5,5), rand_range(-5,5))
	
	if athlete.team.isHuman:
		ball.TouchedByA()
	else:
		ball.TouchedByB()
	
	athlete.team.receptionTarget = receptionTarget
		
	#Bizzare physics hack needed
	ball.linear_velocity = (ball.FindWellBehavedParabola(ball.transform.origin, receptionTarget, rand_range(4,8)))
	yield(athlete.get_tree(),"idle_frame")
	ball.linear_velocity = (ball.FindWellBehavedParabola(ball.transform.origin, receptionTarget, rand_range(4,8)))

	athlete.get_tree().get_root().get_node("MatchScene").BallReceived(athlete.team.isHuman)

	yield(athlete.get_tree().create_timer(.5), "timeout")
	athlete.RotateDigPlatform(0)
	if athlete.role == Enums.Role.Setter:
		athlete.stateMachine.SetCurrentState(athlete.defendState)
	else:
		athlete.stateMachine.SetCurrentState(athlete.transitionState)
