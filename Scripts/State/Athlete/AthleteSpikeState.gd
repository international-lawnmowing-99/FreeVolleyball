extends "res://Scripts/State/AthleteState.gd"
class_name AthleteSpikeState
const Enums = preload("res://Scripts/World/Enums.gd")

enum SpikeState {
NotSpiking,
ChoiceConfirmed,
Runup,
Jump
}

const ballRadius = 0.13

var takeOffXZ:Vector3
var landingXZ:Vector3
var timeTillJumpPeak
var spikeState = SpikeState.NotSpiking
#var athlete:Athlete
var spikeValue:float = 0
var runupStartPosition:Vector3

var leftBlockerLeftCoverage
var leftBlockerRightCoverage

var middleBlockerLeftCoverage
var middleBlockerRightCoverage

var rightBlockerLeftCoverage
var rightBlockerRightCoverage

func Enter(athlete:Athlete):
	athlete.debug1.position.y = athlete.position.y + athlete.stats.height * 1.25
	athlete.animTree.set("parameters/state/transition_request", "moving")
	nameOfState="Spike"
	if !athlete.setRequest:
		print(athlete.stats.lastName + ": " + Enums.Role.keys()[athlete.role])
		athlete.setRequest = athlete.middleSpikes[0]
	CalculateTakeOffXZ(athlete)
	spikeState = SpikeState.ChoiceConfirmed

func Update(athlete:Athlete):
	#if athlete.team.flip == 1 && athlete.rotationPosition == 2:
		#print(spikeState)
	match spikeState:
		SpikeState.NotSpiking:
			pass
			
		SpikeState.ChoiceConfirmed:
#			if athlete == athlete.team.oppositeHitter:
#				var a
			CalculateTakeOffXZ(athlete)
	
			var timeTillBallReachesSetTarget:float = CalculateTimeTillBallReachesSetTarget(athlete)

#			Console.AddNewLine("time till set target apparently... ")
			if timeTillBallReachesSetTarget <= athlete.CalculateTimeTillJumpPeak(takeOffXZ) && athlete.team.stateMachine.currentState != athlete.team.receiveState:
				spikeState = SpikeState.Runup
				athlete.moveTarget = takeOffXZ
				athlete.model.look_at(takeOffXZ, Vector3.UP, true)
#				Console.AddNewLine(athlete.stats.lastName)
#				Console.AddNewLine("time to set target: " + str("%0.3f" % timeTillBallReachesSetTarget))
#				Console.AddNewLine("time till jump peak: " + str("%0.3f" % athlete.CalculateTimeTillJumpPeak(takeOffXZ)))
#				athlete.team.spikeState.timeStart = Time.get_unix_time_from_system()
#				print(athlete.stats.lastName + " " + str(athlete.CalculateTimeTillJumpPeak(takeOffXZ)))
#				print(str(timeTillBallReachesSetTarget) + str(athlete.team.stateMachine.currentState))

		SpikeState.Runup:
			if athlete.team.flip * athlete.position.x <= abs(takeOffXZ.x + athlete.team.flip * 0.05): #Maths.XZVector(takeOffXZ - athlete.position).length() < 0.1:
				spikeState = SpikeState.Jump
				athlete.rightIK.start()
				athlete.rightIK.interpolation = 1
				if athlete.rb.freeze:
					athlete.rb.freeze = false
					athlete.rb.gravity_scale = 1
					# We want to contact the ball at our max height...
					# This means a steeper jump for more extreme verticals
					athlete.rb.linear_velocity = Maths.FindWellBehavedParabola(athlete.position, landingXZ, athlete.stats.verticalJump)
					if athlete == athlete.team.chosenSpiker:
						ChooseSpikingStrategy(athlete)
						
		SpikeState.Jump:
			athlete.rightIKTarget.global_transform.origin = athlete.ball.position

			if athlete.position.y <= 0.05 && athlete.rb.linear_velocity.y < 0:
				athlete.rb.freeze = true
				athlete.rb.gravity_scale = 0
				athlete.position.y = 0
				athlete.moveTarget = athlete.position
				#athlete.PrepareToDefend()
				spikeState = SpikeState.NotSpiking
				athlete.ReEvaluateState()
	
func CalculateTakeOffXZ(athlete:Athlete):

#	takeOffXZ = Vector3(athlete.setRequest.target.x + athlete.team.flip * athlete.stats.verticalJump/2, 0, athlete.setRequest.target.z)
#	return
	if athlete.team.flip * athlete.setRequest.target.x <= 0.1:
		Console.AddNewLine("ERROR! SetRequest too close to net", Color.BROWN)
		return
	# The parabola is centred on the jump peak, which is the setRequest target
	var halfHorizJump:float = athlete.stats.verticalJump/2
	var currentMoveVector:Vector3 = Maths.XZVector(athlete.setRequest.target - athlete.position)
	var flippedProjectionTowardsNet:Vector3 = athlete.team.flip * Maths.XZVector(athlete.setRequest.target) + halfHorizJump * athlete.team.flip * currentMoveVector.normalized() 
	
	if flippedProjectionTowardsNet.x <= 0:
		Console.AddNewLine(athlete.stats.lastName + " is going to jump through the net on current trajectory")
#		Console.AddNewLine("Set request: " + str(athlete.setRequest.target))
#		Console.AddNewLine("Jump length: " + str("%0.1f" % halfHorizJump))
#		Console.AddNewLine("Current move vector: " + str(currentMoveVector.normalized()))

		# Full jump would take them through the net - shorten horizontal jump
		var flippedLandingX:float = 0.1
		var flippedSetTargetX = athlete.team.flip * athlete.setRequest.target.x
		var jumpReductionFraction = (flippedSetTargetX - flippedLandingX)/(flippedSetTargetX - flippedProjectionTowardsNet.x)
		var flippedLandingZ = athlete.team.flip * athlete.setRequest.target.z + jumpReductionFraction * (athlete.team.flip * athlete.setRequest.target.z - flippedProjectionTowardsNet.z)
	
		var flippedLandingPos = Vector3(flippedLandingX, 0, flippedLandingZ)
		var flippedTakeOffXZ = 2 * athlete.team.flip * Maths.XZVector(athlete.setRequest.target) - flippedLandingPos
		
		takeOffXZ = athlete.team.flip * flippedTakeOffXZ
		landingXZ = athlete.team.flip * flippedLandingPos
#		athlete.team.mManager.cube.position = takeOffXZ
#		athlete.team.mManager.cylinder.position = landingXZ
#		athlete.team.mManager.sphere.position = Maths.XZVector(athlete.setRequest.target)
	else:
		# Otherwise takeoff is just the landing vector reversed - visually this is a nice parallelogram!
		takeOffXZ = 2 * Maths.XZVector(athlete.setRequest.target) - athlete.team.flip * flippedProjectionTowardsNet
		landingXZ = athlete.team.flip * flippedProjectionTowardsNet
#	athlete.team.mManager.cube.position = takeOffXZ

func Exit(athlete:Athlete):
	athlete.rightIK.interpolation = 0
	pass

#func ReactToDodgySet():
#	pass

#func TimeToSpikeWithFullRunup() -> float:
#	var timeToGetToRunup = athlete.distance_to(athlete.spikeState.runupStartPosition)/athlete.stats.speed 
#	var timeToRunup = runupStartPosition.distance_to(takeOffXZ)/athlete.stats.speed
#	var timeToReach
func CalculateTimeTillBallReachesSetTarget(athlete:Athlete) -> float:
	var setTime:float
	var yVel:float
			# Setting downwards
	if athlete.setRequest.height <= athlete.team.receptionTarget.y:
		if athlete.team.stateMachine.currentState == athlete.team.spikeState:
			var distanceFactor:float = 1 - Vector3(athlete.ball.position.x, 0, athlete.ball.position.z).distance_to(Maths.XZVector(athlete.team.receptionTarget))/ (Maths.XZVector(athlete.team.receptionTarget).distance_to(Maths.XZVector(athlete.setRequest.target)))
			setTime = distanceFactor * Maths.SetTimeDownwardsParabola(athlete.team.receptionTarget, athlete.setRequest.target) 
		else:
			setTime = Maths.SetTimeDownwardsParabola(athlete.team.receptionTarget, athlete.setRequest.target)
		
	else:
		# Standard set
		yVel = sqrt(2 * athlete.g * abs(athlete.setRequest.height - athlete.team.receptionTarget.y))
		if athlete.team.stateMachine.currentState == athlete.team.spikeState:
			var distanceFactor:float = 1 - Vector3(athlete.ball.position.x, 0, athlete.ball.position.z).distance_to(Maths.XZVector(athlete.team.receptionTarget))/ (Maths.XZVector(athlete.team.receptionTarget).distance_to(Maths.XZVector(athlete.setRequest.target)))
			setTime = distanceFactor * (yVel / athlete.g + sqrt(2 * athlete.g * abs(athlete.setRequest.height - athlete.setRequest.target.y)) / athlete.g)
		else:
			setTime = yVel / athlete.g + sqrt(2 * athlete.g * abs(athlete.setRequest.height - athlete.setRequest.target.y)) / athlete.g
		
	return athlete.team.timeTillDigTarget + setTime

func ChooseSpikingStrategy(athlete:Athlete):
	var ball = athlete.ball
	Console.AddNewLine("_____________________________________________________________", Color.TOMATO)
	Console.AddNewLine("Chosen spiker " + athlete.stats.lastName + " choosing spiking strategy", Color.TOMATO)
	ReadBlock(athlete, athlete.team.defendState.otherTeam)
	ReadDefence(athlete, athlete.team.defendState.otherTeam)
	
	# Now that we know what the block and defence are doing, assign a number
	# to each of the various ways to try to hit the ball

	# Is the set good enough to do everything the spiker wants to do? 
	
	if athlete.setRequest.target.y <= 2.43:
		Console.AddNewLine("Spike contact will be lower than the net")
		# Can only tip or roll or tool high
	
	# If they are within the antennae, then the whole court area is open, 
	# but spiking wide means that line is unavailable
	
	var playerToNetVector = Vector3(-athlete.setRequest.target.x, 0, 0)
	var playerToLeftAntennaVector = Vector3(-athlete.setRequest.target.x, 0, athlete.team.flip * (4.5 - ballRadius) - athlete.setRequest.target.z)
	var playerToRightAntennaVector = Vector3(-athlete.setRequest.target.x, 0, athlete.team.flip * (-4.5 + ballRadius) - athlete.setRequest.target.z)
#	athlete.team.mManager.cube.position = Maths.XZVector(athlete.setRequest.target + playerToNetVector)
	
#	athlete.team.mManager.cylinder.position = Maths.XZVector(athlete.setRequest.target + playerToLeftAntennaVector)
	var angleToLeftAntenna = Maths.SignedAngle(playerToNetVector, playerToLeftAntennaVector, Vector3.DOWN)
	var angleToRightAntenna = Maths.SignedAngle(playerToNetVector, playerToRightAntennaVector, Vector3.DOWN)
#	Console.AddNewLine(str("%.1f" % rad_to_deg(angleToLeftAntenna)) + " degrees to left antenna")
#	Console.AddNewLine(str("%.1f" % rad_to_deg(angleToRightAntenna)) + " degrees to right antenna")
#
#	Console.AddNewLine("Choosing an angle between the two", Color.LIME_GREEN)

	
	# We need to be able to list the angles available in terms of:
	# a) left antenna to left blocker left hand
	# b) left blocker right hand to middle blocker left hand
	# c) middle blocker right hand to right blocker left hand
	# d) right blocker right hand to right antenna
	# (and be able to cull out non-present/ non perceived blockers)
	
	# Then we need to work out if a powerful spike can be attempted in each of those corridors
	# Or do we want to use another option, probably enumerated elsewhere
	# So we need to find the lowest possible spike for the leftmost and rightmost extremities
	# of a, b, c, and d, should they exist
	# if both extremities are shorter than the longest possible spike distance, then a max power
	# - lowest netpass swing is possible between these ranges. 
	# Then we can look at the fastest spike that will achieve max depth. This will be slower 
	# than max power, and we scale down the expected value of the spike accordingly
	# If only one extremity can accomodate the max power spike, we can work out the max power
	# spike distance, and where it intersects with the court boundaries to come up with a range 
	# of angles that we can crank in
	
	# Weight the desirability of each option based on a mixture of expected point scoring value
	# plus the athlete's internal quirks, then randomly choose between the options
	
	
	
	var lineCross = randf()
	var spikeAngleTopDown = lerp(angleToLeftAntenna, angleToRightAntenna, lineCross)
#	spikeAngleTopDown = PI/4
#	Console.AddNewLine(str("%.1f" % rad_to_deg(spikeAngleTopDown)) + " potential spike angle")
	
	var furthestCourtPoint:Vector3
	# Find the nearest intersection to the edge of the court along the line
	# of the angle to work out how long the spike can be
	var topDownSpikeVector:Vector3 = Vector3(-athlete.team.flip, 0, 0).rotated(Vector3.DOWN, spikeAngleTopDown)
#	Console.AddNewLine(str(topDownSpikeVector) + " spike vector")
	# Using our old friend y = mx + b (But with z as y)
	var m:float = topDownSpikeVector.z / topDownSpikeVector.x
#	Console.AddNewLine(str("%.1f" % m) + " m")
	var b:float = athlete.setRequest.target.z - m * athlete.setRequest.target.x
#	Console.AddNewLine(str("%.1f" % athlete.setRequest.target.z) + " set request z", Color.FUCHSIA)
#	Console.AddNewLine(str("%.1f" % athlete.setRequest.target.x) + " set request x", Color.FUCHSIA)
#	Console.AddNewLine(str("%.1f" % b) + " b")
	
	var baselineZIntercept:float = m * 9 * -athlete.team.flip + b
	# If the baseline intercept is wider than the antennae, the ball is out on the side first
	if abs(baselineZIntercept) > 4.5:
		var leftSideXIntercept:float = (4.5 - b)/m
		var rightSideXIntercept:float = (-4.5 - b)/m
#		Console.AddNewLine(str("%.1f" % leftSideXIntercept) + " left x intercept")
#		Console.AddNewLine(str("%.1f" % rightSideXIntercept) + " right x intercept")
		if sign(leftSideXIntercept) == sign(rightSideXIntercept):
			Console.AddNewLine("Ball trajectory doesn't cross net inside antennae")
		if sign(leftSideXIntercept) == athlete.team.flip:
			furthestCourtPoint = Vector3(rightSideXIntercept, 0, -4.5)
		else:
			furthestCourtPoint = Vector3(leftSideXIntercept, 0, 4.5)
	else:
		furthestCourtPoint = Vector3(9 * -athlete.team.flip, 0, baselineZIntercept)
	
	var u = 27.78 # 100 kph spike
	var topspin = 3.0
	
	var lowestNetPass = Vector3(0, 2.43 + 0.35, b)
#	athlete.team.mManager.cylinder.position = lowestNetPass
	var lowestPossibleSpike = Maths.FindParabolaForGivenSpeed(athlete.setRequest.target, lowestNetPass, u, false, topspin)

	var closestPossibleSpikeTarget:Vector3 = Maths.BallPositionAtGivenHeight(athlete.setRequest.target, lowestPossibleSpike, 0, topspin)
	
	var spikeDepth:float = randf_range(0.03, .97)
	athlete.ball.attackTarget = closestPossibleSpikeTarget

# if the furthest point is closer than the edge of the court, choose some depth randomly
	if -athlete.team.flip * furthestCourtPoint.x > -athlete.team.flip * closestPossibleSpikeTarget.x:
		if closestPossibleSpikeTarget.z > -4.5 && closestPossibleSpikeTarget.z < 4.5:
			athlete.ball.attackTarget = lerp(closestPossibleSpikeTarget, furthestCourtPoint, spikeDepth)
	
	# Otherwise though, it's just flying long currently...
	
	
#	athlete.team.mManager.sphere.position = closestPossibleSpikeTarget
#	athlete.team.mManager.cube.position = athlete.ball.attackTarget
#	athlete.team.mManager.cylinder.position = furthestCourtPoint

#	athlete.ball.attackTarget = Maths.XZVector(lerp(athlete.ball.FindNetPass(), furthestCourtPoint, spikeDepth))

#	athlete.team.mManager.cylinder.position = Maths.XZVector(athlete.setRequest.target)
#	athlete.team.mManager.cube.position = Maths.XZVector(athlete.setRequest.target) + topDownSpikeVector
#	Console.AddNewLine(str("%.1f" % baselineZIntercept) + " baseline z intercept")
	var vel = Maths.FindParabolaForGivenSpeed(athlete.setRequest.target, ball.attackTarget, u, false, 3.0)
	athlete.team.mManager.cylinder.position = Maths.FindNetPass(athlete.setRequest.target, ball.attackTarget, vel, 3.0)
#	Console.AddNewLine("Predicted net pass: " + str(athlete.team.mManager.cylinder.position))
	var longestPossibleSpikeXZDistance = Maths.XZVector(athlete.setRequest.target).distance_to(furthestCourtPoint)
#	Console.AddNewLine(str("%.1f" % longestPossibleSpikeXZDistance) + " max possible spike distance")
	
	
	
	
	# What is their preference as to hitting line or cross? 
	# How aggressively will they swing? 
	Console.AddNewLine("End choice of initial spiking plan", Color.TOMATO)
	Console.AddNewLine("_____________________________________________________________", Color.TOMATO)
	
func ReadBlock(athlete:Athlete, otherTeam:Team):
	var ball = athlete.ball
	Console.AddNewLine("Reading block")
	
	var oppositionLeftBlocker = otherTeam.defendState.leftSideBlocker
	var oppositionMiddleBlocker = otherTeam.defendState.middleBlocker
	var oppositionRightBlocker = otherTeam.defendState.rightSideBlocker
	
	
	var leftBlockerPossiblePosition
	var middleBlockerPossiblePosition
	var rightBlockerPossiblePosition
	

	
	var timeTillSpikeContact = Maths.TimeTillBallReachesHeight(ball.position, ball.linear_velocity, athlete.stats.spikeHeight, 1.0)
	
	var timeDelay = athlete.myDelta * 5
	
#	Console.AddNewLine("Assuming blocker will jump for max height at the time of spike contact")
	
	if athlete.setRequest.target.z * athlete.team.flip > 1.5:
		Console.AddNewLine("Opposing right blocker will set block")
		
		if timeTillSpikeContact < oppositionRightBlocker.blockState.jumpTime:
			# They've already jumped
#			Console.AddNewLine("Right blocker position set: has already jumped")
			rightBlockerPossiblePosition = oppositionRightBlocker.position
			rightBlockerLeftCoverage = oppositionRightBlocker.position.z - athlete.team.flip * oppositionRightBlocker.stats.height/3
			rightBlockerRightCoverage = oppositionRightBlocker.position.z + athlete.team.flip * oppositionRightBlocker.stats.height/3
			
		else:
			var moveTime = timeTillSpikeContact - oppositionRightBlocker.blockState.jumpTime

			var moveDistance = oppositionRightBlocker.stats.speed * moveTime
			
			rightBlockerPossiblePosition = oppositionRightBlocker.position + moveDistance * (oppositionRightBlocker.moveTarget - Maths.XZVector(oppositionRightBlocker.position)).normalized()
			
			rightBlockerLeftCoverage = rightBlockerPossiblePosition.z - athlete.team.flip * oppositionRightBlocker.stats.height/3
			rightBlockerRightCoverage = rightBlockerPossiblePosition.z + athlete.team.flip * oppositionRightBlocker.stats.height/3
			
#		var rightBlockerTime = mainBlocker.moveTarget.distance_to(mainBlocker.position) / mainBlocker.stats.speed + mainBlocker.blockState.timeTillBlockPeak
		
#		if rightBlockerTime <= timeTillSpikeContact + timeDelay:
#			Console.AddNewLine("Other team's right blocker will be in position")
		
		if oppositionMiddleBlocker.blockState.blockingTarget == athlete:
			# Has the middle jumped on our middle?
			var middleLandingTime = 0
			if !oppositionMiddleBlocker.rb.freeze:
				Console.AddNewLine("Opposition middle has already jumped")
				middleLandingTime = Maths.TimeTillBallReachesHeight(oppositionMiddleBlocker.position, oppositionMiddleBlocker.linear_velocity, 0, 1.0)
			
			if timeTillSpikeContact < oppositionMiddleBlocker.blockState.jumpTime + middleLandingTime:
				# The middle has already jumped, or won't land in time to jump again
				middleBlockerPossiblePosition = oppositionMiddleBlocker.position
				
				middleBlockerLeftCoverage = oppositionMiddleBlocker.position.z - athlete.team.flip * oppositionMiddleBlocker.stats.height/3
				middleBlockerRightCoverage = oppositionMiddleBlocker.position.z + athlete.team.flip * oppositionMiddleBlocker.stats.height/3
				
			else: 
				var moveTime = timeTillSpikeContact - oppositionMiddleBlocker.blockState.jumpTime - middleLandingTime
				var moveDistance = oppositionMiddleBlocker.stats.speed * moveTime
				
				middleBlockerPossiblePosition = oppositionMiddleBlocker.position + moveDistance * (oppositionMiddleBlocker.moveTarget - Maths.XZVector(oppositionMiddleBlocker.position)).normalized()
				
				middleBlockerLeftCoverage = middleBlockerPossiblePosition.z - athlete.team.flip * oppositionMiddleBlocker.stats.height/3
				middleBlockerRightCoverage = middleBlockerPossiblePosition.z + athlete.team.flip * oppositionMiddleBlocker.stats.height/3
	
#			var middleBlockerTime = theirMiddle.moveTarget.distance_to(theirMiddle.position) / theirMiddle.stats.speed + theirMiddle.blockState.jumpTime
#			if middleBlockerTime <= timeTillSpikeContact + timeDelay:
#				Console.AddNewLine("Other team's middle will make a double block")
#			else:
#				Console.AddNewLine("Other team's middle will try to help, but won't close the seam")
		else:
			Console.AddNewLine("Middle not targetting spiker, nor should the left blocker really...")
		
		if oppositionLeftBlocker.blockState.blockingTarget == athlete:
			# Is the middle on the ground, or has alternativele gotten to within an arbitrary 1.5 metres of the pin blocker?
			# Otherwise too much seam
			if oppositionMiddleBlocker.rb.freeze || Maths.XZVector(oppositionMiddleBlocker.position).distance_to(Maths.XZVector(oppositionLeftBlocker.position)) < 1.5:
				Console.AddNewLine("Opposing left blocker can try to join a triple if they so desire")
				if timeTillSpikeContact < oppositionLeftBlocker.blockState.jumpTime:
					leftBlockerPossiblePosition = oppositionLeftBlocker.position
					leftBlockerLeftCoverage = leftBlockerPossiblePosition.z - athlete.team.flip * oppositionLeftBlocker.stats.height/3
					leftBlockerRightCoverage = leftBlockerPossiblePosition.z + athlete.team.flip * oppositionLeftBlocker.stats.height/3
					
				else:
					var moveTime = timeTillSpikeContact - oppositionLeftBlocker.blockState.jumpTime
					var moveDistance = oppositionLeftBlocker.stats.speed * moveTime
				
					leftBlockerPossiblePosition = oppositionLeftBlocker.position + moveDistance * (oppositionLeftBlocker.moveTarget - Maths.XZVector(oppositionLeftBlocker.position)).normalized()
				
					leftBlockerLeftCoverage = leftBlockerPossiblePosition.z - athlete.team.flip * oppositionLeftBlocker.stats.height/3
					leftBlockerRightCoverage = leftBlockerPossiblePosition.z + athlete.team.flip * oppositionLeftBlocker.stats.height/3
				
		
	elif athlete.setRequest.target.z * athlete.team.flip > -1.5:
		Console.AddNewLine("Opposing middle will set block")
		
		var middleLandingTime = 0
		if !oppositionMiddleBlocker.rb.freeze:
			Console.AddNewLine("Opposition middle has already jumped")
			middleLandingTime = Maths.TimeTillBallReachesHeight(oppositionMiddleBlocker.position, oppositionMiddleBlocker.linear_velocity, 0, 1.0)
			
		if timeTillSpikeContact < oppositionMiddleBlocker.blockState.jumpTime + middleLandingTime:
#			Console.AddNewLine("Middle position set: has already jumped")
				middleBlockerPossiblePosition = oppositionMiddleBlocker.position
				
				middleBlockerLeftCoverage = oppositionMiddleBlocker.position.z - athlete.team.flip * oppositionMiddleBlocker.stats.height/3
				middleBlockerRightCoverage = oppositionMiddleBlocker.position.z + athlete.team.flip * oppositionMiddleBlocker.stats.height/3

		else:
				var moveTime = timeTillSpikeContact - oppositionMiddleBlocker.blockState.jumpTime - middleLandingTime
				var moveDistance = oppositionMiddleBlocker.stats.speed * moveTime
				
				middleBlockerPossiblePosition = oppositionMiddleBlocker.position + moveDistance * (oppositionMiddleBlocker.moveTarget - Maths.XZVector(oppositionMiddleBlocker.position)).normalized()
				
				middleBlockerLeftCoverage = middleBlockerPossiblePosition.z - athlete.team.flip * oppositionMiddleBlocker.stats.height/3
				middleBlockerRightCoverage = middleBlockerPossiblePosition.z + athlete.team.flip * oppositionMiddleBlocker.stats.height/3

		# Can the left blocker get over?
		if oppositionLeftBlocker.rb.freeze:
			var moveTime = timeTillSpikeContact - oppositionLeftBlocker.blockState.jumpTime
			var moveDistance = oppositionLeftBlocker.stats.speed * moveTime

			leftBlockerPossiblePosition = oppositionLeftBlocker.position + moveDistance * (oppositionLeftBlocker.moveTarget - Maths.XZVector(oppositionLeftBlocker.position)).normalized()

			leftBlockerLeftCoverage = leftBlockerPossiblePosition.z - athlete.team.flip * oppositionLeftBlocker.stats.height/3
			leftBlockerRightCoverage = leftBlockerPossiblePosition.z + athlete.team.flip * oppositionLeftBlocker.stats.height/3
			
		else:
			leftBlockerLeftCoverage = oppositionLeftBlocker.position.z - athlete.team.flip * oppositionLeftBlocker.stats.height/3
			leftBlockerRightCoverage = oppositionLeftBlocker.position.z + athlete.team.flip * oppositionLeftBlocker.stats.height/3
			
		if oppositionRightBlocker.rb.freeze:
			var moveTime = timeTillSpikeContact - oppositionRightBlocker.blockState.jumpTime
			var moveDistance = oppositionRightBlocker.stats.speed * moveTime

			rightBlockerPossiblePosition = oppositionRightBlocker.position + moveDistance * (oppositionRightBlocker.moveTarget - Maths.XZVector(oppositionRightBlocker.position)).normalized()

			rightBlockerLeftCoverage = rightBlockerPossiblePosition.z - athlete.team.flip * oppositionRightBlocker.stats.height/3
			rightBlockerRightCoverage = rightBlockerPossiblePosition.z + athlete.team.flip * oppositionRightBlocker.stats.height/3
			
		else:
			rightBlockerLeftCoverage = oppositionRightBlocker.position.z - athlete.team.flip * oppositionRightBlocker.stats.height/3
			rightBlockerRightCoverage = oppositionRightBlocker.position.z + athlete.team.flip * oppositionRightBlocker.stats.height/3
	else:
		Console.AddNewLine("Opposing left blocker will set block")
		if timeTillSpikeContact < oppositionLeftBlocker.blockState.jumpTime:
			# They've already jumped
#			Console.AddNewLine("Right blocker position set: has already jumped")
			leftBlockerPossiblePosition = oppositionRightBlocker.position
			leftBlockerLeftCoverage = oppositionLeftBlocker.position.z - athlete.team.flip * oppositionLeftBlocker.stats.height/3
			leftBlockerRightCoverage = oppositionLeftBlocker.position.z + athlete.team.flip * oppositionLeftBlocker.stats.height/3
			
		else:
			var moveTime = timeTillSpikeContact - oppositionLeftBlocker.blockState.jumpTime

			var moveDistance = oppositionLeftBlocker.stats.speed * moveTime
			
			leftBlockerPossiblePosition = oppositionLeftBlocker.position + moveDistance * (oppositionRightBlocker.moveTarget - Maths.XZVector(oppositionLeftBlocker.position)).normalized()
			
			leftBlockerLeftCoverage = leftBlockerPossiblePosition.z - athlete.team.flip * oppositionLeftBlocker.stats.height/3
			leftBlockerRightCoverage = leftBlockerPossiblePosition.z + athlete.team.flip * oppositionLeftBlocker.stats.height/3
		
		if oppositionMiddleBlocker.blockState.blockingTarget == athlete:
			# Has the middle jumped on our middle?
			var middleLandingTime = 0
			if !oppositionMiddleBlocker.rb.freeze:
				Console.AddNewLine("Opposition middle has already jumped")
				middleLandingTime = Maths.TimeTillBallReachesHeight(oppositionMiddleBlocker.position, oppositionMiddleBlocker.linear_velocity, 0, 1.0)
			
			if timeTillSpikeContact < oppositionMiddleBlocker.blockState.jumpTime + middleLandingTime:
				# The middle has already jumped, or won't land in time to jump again
				middleBlockerPossiblePosition = oppositionMiddleBlocker.position
				
				middleBlockerLeftCoverage = oppositionMiddleBlocker.position.z - athlete.team.flip * oppositionMiddleBlocker.stats.height/3
				middleBlockerRightCoverage = oppositionMiddleBlocker.position.z + athlete.team.flip * oppositionMiddleBlocker.stats.height/3
				
			else: 
				var moveTime = timeTillSpikeContact - oppositionMiddleBlocker.blockState.jumpTime - middleLandingTime
				var moveDistance = oppositionMiddleBlocker.stats.speed * moveTime
				
				middleBlockerPossiblePosition = oppositionMiddleBlocker.position + moveDistance * (oppositionMiddleBlocker.moveTarget - Maths.XZVector(oppositionMiddleBlocker.position)).normalized()
				
				middleBlockerLeftCoverage = middleBlockerPossiblePosition.z - athlete.team.flip * oppositionMiddleBlocker.stats.height/3
				middleBlockerRightCoverage = middleBlockerPossiblePosition.z + athlete.team.flip * oppositionMiddleBlocker.stats.height/3
			
		if oppositionRightBlocker.blockState.blockingTarget == athlete:
			if oppositionMiddleBlocker.rb.freeze || Maths.XZVector(oppositionMiddleBlocker.position).distance_to(Maths.XZVector(oppositionLeftBlocker.position)) < 1.5:
				Console.AddNewLine("Opposing right blocker can try to join a triple if they so desire")
				if timeTillSpikeContact < oppositionRightBlocker.blockState.jumpTime:
					rightBlockerPossiblePosition = oppositionRightBlocker.position
					rightBlockerLeftCoverage = rightBlockerPossiblePosition.z - athlete.team.flip * oppositionRightBlocker.stats.height/3
					rightBlockerRightCoverage = rightBlockerPossiblePosition.z + athlete.team.flip * oppositionRightBlocker.stats.height/3
					
				else:
					var moveTime = timeTillSpikeContact - oppositionRightBlocker.blockState.jumpTime
					var moveDistance = oppositionRightBlocker.stats.speed * moveTime
				
					rightBlockerPossiblePosition = oppositionRightBlocker.position + moveDistance * (oppositionRightBlocker.moveTarget - Maths.XZVector(oppositionRightBlocker.position)).normalized()
				
					rightBlockerLeftCoverage = rightBlockerPossiblePosition.z - athlete.team.flip * oppositionRightBlocker.stats.height/3
					rightBlockerRightCoverage = rightBlockerPossiblePosition.z + athlete.team.flip * oppositionRightBlocker.stats.height/3
	
	

	
	var playerToNetVector = Vector3(-athlete.setRequest.target.x, 0, 0)
	
	if !rightBlockerLeftCoverage:
		Console.AddNewLine("Couldn't see their right blocker, maybe you can though", Color.LIME_GREEN)
	else:
		var playerToRightLeft = Vector3(-athlete.setRequest.target.x, 0, rightBlockerLeftCoverage - athlete.setRequest.target.z)
		var playerToRightRight = Vector3(-athlete.setRequest.target.x, 0, rightBlockerRightCoverage - athlete.setRequest.target.z)	
		var angleToRightLeft = Maths.SignedAngle(playerToNetVector, playerToRightLeft, Vector3.DOWN)
		var angleToRightRight = Maths.SignedAngle(playerToNetVector, playerToRightRight, Vector3.DOWN)
		
#		Console.AddNewLine(str("%.1f" % rad_to_deg(angleToRightRight)) + " degrees to (opposition perspective) right blocker right hand")
#		Console.AddNewLine(str("%.1f" % rad_to_deg(angleToRightLeft)) + " degrees to (opposition perspective) right blocker left hand")
		
	if !middleBlockerLeftCoverage:
		Console.AddNewLine("Couldn't see a middle block, maybe you can though", Color.LIME_GREEN)
	else:
		athlete.team.mManager.cube.position = Vector3(0, oppositionMiddleBlocker.stats.blockHeight, middleBlockerLeftCoverage)
		athlete.team.mManager.sphere.position = Vector3(0, oppositionMiddleBlocker.stats.blockHeight, middleBlockerRightCoverage)				
		
		var playerToMiddleLeft = Vector3(-athlete.setRequest.target.x, 0, middleBlockerLeftCoverage - athlete.setRequest.target.z)
		var playerToMiddleRight = Vector3(-athlete.setRequest.target.x, 0, middleBlockerRightCoverage - athlete.setRequest.target.z)
		var angleToMiddleLeft = Maths.SignedAngle(playerToNetVector, playerToMiddleLeft, Vector3.DOWN)
		var angleToMiddleRight = Maths.SignedAngle(playerToNetVector, playerToMiddleRight, Vector3.DOWN)
		
#		Console.AddNewLine(str("%.1f" % rad_to_deg(angleToMiddleRight)) + " degrees to (opposition perspective) middle blocker right hand")		
#		Console.AddNewLine(str("%.1f" % rad_to_deg(angleToMiddleLeft)) + " degrees to (opposition perspective) middle blocker left hand")
	
	
	if !leftBlockerLeftCoverage:
		Console.AddNewLine("Couldn't see their left blocker, maybe you can though", Color.LIME_GREEN)
	else:

		
		var playerToLeftLeft = Vector3(-athlete.setRequest.target.x, 0, leftBlockerLeftCoverage - athlete.setRequest.target.z)
		var playerToLeftRight = Vector3(-athlete.setRequest.target.x, 0, leftBlockerRightCoverage - athlete.setRequest.target.z)
		var angleToLeftLeft = Maths.SignedAngle(playerToNetVector, playerToLeftLeft, Vector3.DOWN)
		var angleToLeftRight = Maths.SignedAngle(playerToNetVector, playerToLeftRight, Vector3.DOWN)
		
#		Console.AddNewLine(str("%.1f" % rad_to_deg(angleToLeftRight)) + " degrees to (opposition perspective) left blocker right hand")
#		Console.AddNewLine(str("%.1f" % rad_to_deg(angleToLeftLeft)) + " degrees to (opposition perspective) left blocker left hand")
	


	
	var flip = athlete.team.flip
	var leftOverlap:bool = false
	var rightOverlap:bool = false
	
	if !middleBlockerLeftCoverage || ! leftBlockerRightCoverage:
		Console.AddNewLine("Middle and left blocker didn't both show up")
	elif flip * middleBlockerLeftCoverage < flip * leftBlockerRightCoverage:
		Console.AddNewLine("Middle and left blocker overlap (Predicted)")
		leftOverlap = true
	else:
		Console.AddNewLine("Middle and left blocker seam (Predicted)")

	if !middleBlockerRightCoverage || ! rightBlockerLeftCoverage:
		Console.AddNewLine("Middle and right blocker didn't both show up")	
	elif flip * middleBlockerRightCoverage > flip * rightBlockerLeftCoverage:
		Console.AddNewLine("Middle and right blocker overlap (Predicted)")	
		rightOverlap = true
	else:
		Console.AddNewLine("Middle and right blocker seam (Predicted)")
		
	if leftOverlap && rightOverlap:
		Console.AddNewLine("Triple Block! (Predicted)", Color.DARK_TURQUOISE)
#	var blockMaximumHeight:float = 0
#	var ballRadius:float = 0.13
#	var opposingBlockers:Array = []
#	for potentialBlocker in otherTeam.courtPlayers:
#		if potentialBlocker.FrontCourt() && potentialBlocker.blockState.blockingTarget == athlete:
#			opposingBlockers.append(potentialBlocker)
#			if potentialBlocker.stats.blockHeight > blockMaximumHeight:
#				blockMaximumHeight = potentialBlocker.stats.blockHeight
#
#	Console.AddNewLine("There are " + str(opposingBlockers.size()) + " blocker(s) to contend with")
#	for i in range (opposingBlockers.size()):
#		Console.AddNewLine(str(i + 1) + ": " + opposingBlockers[i].stats.lastName + " || " + str("%.0f"%(opposingBlockers[i].stats.blockHeight * 100)))
	
	
	# Will the block unify into a double or triple, or will there be a big seam? 
#	var timeBetweenSpikeAndNetCross = 
	
	
	# The block has no seam/minimal seam if the blockers can get to within 0.75 of each other
	
	# Who is the blocker that will set the block position? 
	# If the ball is in the left third, their right blocker, middle third: their middle obviously, etc
#	var mainBlocker:Athlete
#
#	if mainBlocker in opposingBlockers:
##		Console.AddNewLine("The relevant blocker will be present", Color.PEACH_PUFF)
#		# We don't really know where the main blocker will set up their jump from
#		# But just assume for now
#
#		# Also assume effective block coverage is 2/3 of the height of the player
#		var mainBlockerLeftBlockCoverageLimit = mainBlocker.position.z + athlete.team.flip * athlete.stats.height/3
#		var mainBlockerRightBlockCoverageLimit = mainBlocker.position.z - athlete.team.flip * athlete.stats.height/3
#
#		Console.AddNewLine("Left main block coverage limit: " + str(mainBlockerLeftBlockCoverageLimit), Color.PEACH_PUFF)
#		Console.AddNewLine("Right main block coverage limit: " + str(mainBlockerRightBlockCoverageLimit), Color.PEACH_PUFF)
#		var playerToNetVector = Vector3(-athlete.setRequest.target.x, 0, 0)
#		var playerToLeftBlockLimitVector = Vector3(-athlete.setRequest.target.x, 0, athlete.team.flip * mainBlockerLeftBlockCoverageLimit - athlete.setRequest.target.z)
#		var playerToRightBlockLimitVector = Vector3(-athlete.setRequest.target.x, 0, athlete.team.flip * mainBlockerRightBlockCoverageLimit - athlete.setRequest.target.z)
#
#		var angleToLeftBlockLimit = Maths.SignedAngle(playerToNetVector, playerToLeftBlockLimitVector, Vector3.DOWN)
#		var angleToRightBlockLimit = Maths.SignedAngle(playerToNetVector, playerToRightBlockLimitVector, Vector3.DOWN)
#		Console.AddNewLine(str("%.1f" % rad_to_deg(angleToLeftBlockLimit)) + " degrees to left block limit")
#		Console.AddNewLine(str("%.1f" % rad_to_deg(angleToRightBlockLimit)) + " degrees to right block limit")
		

	
	
	
#	if athlete.stats.spikeHeight - ballRadius > blockMaximumHeight:
#		Console.AddNewLine("Spiker will OTT block")
	
func ReadDefence(athlete:Athlete, otherTeam:Team):
	Console.AddNewLine("Reading defence " + athlete.stats.lastName + " " + otherTeam.teamName)
	var defenders:Array = []
	for lad in otherTeam.courtPlayers:
		if !lad.FrontCourt():
			defenders.append(lad)
	defenders.sort_custom(func(a,b): return otherTeam.flip * a.moveTarget.z > otherTeam.flip * b.moveTarget.z)
	
	if defenders.size() < 3:
		Console.AddNewLine("ERROR: DEFENDERS NOT FOUND", Color.RED)
		return
	
	var leftDefender = defenders[0]
	var middleDefender = defenders[1]
	var rightDefender = defenders[2]
	var distanceToLeftDefender:float = athlete.setRequest.target.distance_to(leftDefender.position)
	var distanceToMiddleDefender:float = athlete.setRequest.target.distance_to(middleDefender.position)
	var distanceToRightDefender:float = athlete.setRequest.target.distance_to(rightDefender.position)
	
	Console.AddNewLine("Distance to left defender (" + leftDefender.stats.lastName + "): " + str("%0.1f"%distanceToLeftDefender))
	Console.AddNewLine("Distance to middle defender(" + middleDefender.stats.lastName + "): " + str("%0.1f"%distanceToMiddleDefender))
	Console.AddNewLine("Distance to right defender(" + rightDefender.stats.lastName + "): " + str("%0.1f"%distanceToRightDefender))
	
	
func CalculateTimeTillSpike(athlete:Athlete):
	var timeToGround:float = 0
	var timeToRunupStart:float = 0
	var runupTime:float = 0
	var jumpTime:float
	
	if athlete.stateMachine.currentState != self || spikeState == SpikeState.ChoiceConfirmed || spikeState == SpikeState.NotSpiking:
		if !athlete.rb.freeze && athlete.position.y > 0:
			timeToGround = Maths.TimeTillBallReachesHeight(athlete.position, athlete.linear_velocity, 0, 1.0)

		if runupStartPosition:
			timeToRunupStart = Maths.XZVector(athlete.position).distance_to(runupStartPosition) / athlete.stats.speed
			runupTime = runupStartPosition.distance_to(takeOffXZ) / athlete.stats.speed
		
	if spikeState == SpikeState.Runup:
		runupTime = Maths.XZVector(athlete.position).distance_to(takeOffXZ) / athlete.stats.speed
	
	if spikeState == SpikeState.Jump:
		if !athlete.rb.freeze:
			if athlete.linear_velocity.y < 0:
				jumpTime = -athlete.linear_velocity.y / athlete.g
			else:
				jumpTime = 0
		else:
			jumpTime = Maths.TimeTillBallReachesHeight(Vector3.UP * athlete.stats.verticalJump, Vector3.ZERO, 0, 1.0)
	else:
		jumpTime = Maths.TimeTillBallReachesHeight(Vector3.UP * athlete.stats.verticalJump, Vector3.ZERO, 0, 1.0)
		
	var a = timeToGround + timeToRunupStart + runupTime + jumpTime
#	Console.AddNewLine(str(a))
	return a
