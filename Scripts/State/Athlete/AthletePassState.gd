extends "res://Scripts/State/AthleteState.gd"
class_name AthletePassState
const Enums = preload("res://Scripts/World/Enums.gd")

var ball:Ball
#var timeTillBallReachesMe
var isBallAlreadyPassed:bool = false

var intersectionPointX
var intersectionPointZ

func Enter(athlete:Athlete):
	isBallAlreadyPassed = false
	nameOfState="pass"
	athlete.animTree.set("parameters/state/transition_request", "digging")
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

	
	var servePos = ball.position
	athlete.moveTarget = ball.BallPositionAtGivenHeight(0.9) + Vector3(0,-.9, randf_range(-.5,.51))
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
	
	
	athlete.digAngle = rad_to_deg(ball.SignedAngle(athlete.transform.basis.z , -athlete.position + Vector3(intersectionPointX,0,intersectionPointZ), Vector3.UP))
	#print("digAngle = " + str(athlete.digAngle))
	#other team is rotated -90, we're 90
	#var angle = atan2(athlete.position.z - intersectionPointZ, athlete.position.x - intersectionPointX) 
	
	#print(str(rad_to_deg(athlete.transform.basis.z[0])))

	#athlete.anglewanted = -athlete.position + Vector3(intersectionPointX,0,intersectionPointZ)


func Update(athlete:Athlete):
#	athlete.get_node("Debug").global_transform.origin = Vector3(intersectionPointX, .5, intersectionPointZ)
	athlete.timeTillBallReachesMe = Vector3(ball.position.x, 0, ball.position.z).distance_to(Vector3(athlete.position.x, 0, athlete.position.z))\
				/max(Vector3(ball.linear_velocity.x, 0, ball.linear_velocity.z).length(), 0.001)
				

	if athlete.timeTillBallReachesMe <1.5:
		athlete.animTree.set("parameters/state/current", 1)
		var animFactor = 1.5-  athlete.timeTillBallReachesMe 
		athlete.animTree.set("parameters/Dig/blend_amount", animFactor)

		athlete.RotateDigPlatform(athlete.digAngle)#( lerp(0,athlete.digAngle,(max(1,1/athlete.timeTillBallReachesMe)))))
	else:
		var a = athlete.animTree.get("parameters/Dig/blend_amount")
		athlete.animTree.set("parameters/Dig/blend_amount", lerp(a, 0.0, 5*athlete.myDelta))
		athlete.digAngle = lerp(athlete.digAngle,0.0,3*athlete.myDelta)
		athlete.RotateDigPlatform(athlete.digAngle)
	if !isBallAlreadyPassed && ball.inPlay && ball.position.y < 1 && ball.position.y > .35 &&\
		(Vector3(ball.position.x,0, ball.position.z)).distance_to(athlete.position) < 1:
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
	var ballMaxHeight
	#perfect pass, 2-pass, 1-pass, shank, some sort of unSafety ball that hits the floor near your feet
	var passRoll = randf_range(0, athlete.stats.reception)
#	Console.AddNewLine("PASSING || PASS ROLL: " + str(int(passRoll)) + " Difficulty: " + str(int(ball.difficultyOfReception)))
	var rollOffDifference = passRoll - ball.difficultyOfReception
#	Console.AddNewLine( str(int(passRoll)) + " out of a possible " + str(int(athlete.stats.reception)), Color.AQUA)
#	Console.AddNewLine( str(int(rollOffDifference)) + " roll unchecked differece ", Color.RED)

	
	if rollOffDifference >= 19:
		# what is the ideal height for the setter to jump set??
		if athlete.role == Enums.Role.Setter:
			if athlete.team.isLiberoOnCourt:
				receptionTarget = Vector3(athlete.team.flip * 3.13, athlete.team.libero.stats.jumpSetHeight, 0)
			else:
				receptionTarget = Vector3(athlete.team.flip * 3.13, athlete.team.middleBack.stats.jumpSetHeight, 0)
		else:
			receptionTarget = Vector3(athlete.team.flip * 0.5, athlete.team.setter.stats.jumpSetHeight, 0)
		
		# for a perfect reception, this needs to be sufficient to give the setter time to jump set
		# even in the unrealistic setup (setter vertical jump >3 metres) we've got now
		
		var setterJumpSetTime = athlete.team.setter.setState.TimeToJumpSet(athlete.team.setter, receptionTarget) + randf_range(.2, 1.0)
		var heightDifferenceToReceptionTarget = receptionTarget.y - ball.position.y
		var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
		
#		initialYVel = (s - 1/2 a t^2)/t
		var initialYVel = (heightDifferenceToReceptionTarget + .5 * gravity * setterJumpSetTime * setterJumpSetTime)/setterJumpSetTime
		
#		time for ball to peak:
#		0 = u + at, t = u/g
		
		var timeForBallPeak = initialYVel/gravity
		ballMaxHeight = initialYVel * initialYVel /(2 * gravity) + ball.position.y

#		ballMaxHeight = randf_range(receptionTarget.y + 0.5, receptionTarget.y + 3.5)
		
		Console.AddNewLine(athlete.stats.lastName + " FUCKING MINT pass")

	elif rollOffDifference >= -10:
		receptionTarget = Vector3(athlete.team.flip * randf_range(1.5, 2.5), 2.5, randf_range(-2, 2))
		ballMaxHeight = randf_range(receptionTarget.y + 0.5, receptionTarget.y + 3.5)
		Console.AddNewLine(athlete.stats.lastName + " 2-point pass")
		pass
	elif rollOffDifference >= -50:
		receptionTarget = Vector3(athlete.position.x + randf_range(-3,3), 2.5, athlete.position.z + randf_range(-3,3))
		
		#prevent the setter chasing overpasses... by removing them! (for now)
		if athlete.team.isHuman:
			receptionTarget.x = max(receptionTarget.x, 0.1)
		else:
			receptionTarget.x = min(receptionTarget.x, -0.1)
		######################################################################
		
		ballMaxHeight = randf_range(receptionTarget.y + 0.5, receptionTarget.y + 3.5)
		Console.AddNewLine(athlete.stats.lastName + " 1-point pass")
#		athlete.team.mManager.cube.position = receptionTarget
		pass	
	else:
		ball.linear_velocity.y *= -1
		ball.linear_velocity *= randf_range(0.5, 1.0)
		
		if ball.BallMaxHeight() >= 2.4:
			receptionTarget = ball.BallPositionAtGivenHeight(2.5)
		else:
			receptionTarget = ball.BallPositionAtGivenHeight(0)
		
		ballMaxHeight = randf_range(receptionTarget.y + 0.5, receptionTarget.y + 3.5)
		Console.AddNewLine(athlete.stats.lastName + " - Shit pass mate")
		pass	



	ball.gravity_scale = 1
	ball.angular_velocity += Vector3 ( randf_range(-5,5),randf_range(-5,5), randf_range(-5,5))
	
	if athlete.team.isHuman:
		ball.TouchedByA()
	else:
		ball.TouchedByB()
	
	athlete.team.receptionTarget = receptionTarget
	

	
	
### IT'S BACK!!! --------------------- (still oddly necessary)
	ball.linear_velocity = ball.FindWellBehavedParabola(ball.position, receptionTarget, ballMaxHeight)
	await athlete.get_tree().process_frame
	ball.linear_velocity = ball.FindWellBehavedParabola(ball.position, receptionTarget, ballMaxHeight)
#### ---------------------------------
#	var receptionTime = athlete.team.ball.SetTimeWellBehavedParabola(ball.position, receptionTarget, ballMaxHeight)
#	Console.AddNewLine("Time till ball at reception target: " + str(receptionTime))

	athlete.get_tree().get_root().get_node("MatchScene").BallReceived(athlete.team.isHuman)

	await athlete.get_tree().create_timer(.5).timeout
	athlete.RotateDigPlatform(0)
	if athlete.role == Enums.Role.Setter:
		athlete.stateMachine.SetCurrentState(athlete.defendState)
	else:
		athlete.stateMachine.SetCurrentState(athlete.transitionState)
