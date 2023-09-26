extends "res://Scripts/State/AthleteState.gd"
class_name AthleteSpikeState
const Enums = preload("res://Scripts/World/Enums.gd")

enum SpikeState {
NotSpiking,
ChoiceConfirmed,
Runup,
Jump
}
var takeOffXZ:Vector3
var landingXZ:Vector3
var timeTillJumpPeak
var spikeState = SpikeState.NotSpiking
#var athlete:Athlete
var spikeValue:float = 0
var runupStartPosition:Vector3

func Enter(athlete:Athlete):
#	athlete.get_node("Debug").global_transform.origin = Vector3.ZERO
	athlete.get_node("Debug").position.y = athlete.position.y + athlete.stats.height * 1.33
	athlete.animTree.set("parameters/state/transition_request", "moving")
	nameOfState="Spike"
	if !athlete.setRequest:
		print(athlete.stats.lastName + ": " + Enums.Role.keys()[athlete.role])
		athlete.setRequest = athlete.middleSpikes[0]
	CalculateTakeOffXZ(athlete)
#	athlete.CalculateTimeTillJumpPeak(takeOffXZ)
	spikeState = SpikeState.ChoiceConfirmed
	pass
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

func ReactToDodgySet():
	pass

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
	var playerToLeftAntennaVector = Vector3(-athlete.setRequest.target.x, 0, athlete.team.flip * 4.5 - athlete.setRequest.target.z)
	var playerToRightAntennaVector = Vector3(-athlete.setRequest.target.x, 0, athlete.team.flip * -4.5 - athlete.setRequest.target.z)
#	athlete.team.mManager.cube.position = Maths.XZVector(athlete.setRequest.target + playerToNetVector)
	
#	athlete.team.mManager.cylinder.position = Maths.XZVector(athlete.setRequest.target + playerToLeftAntennaVector)
	var angleToLeftAntenna = Maths.SignedAngle(playerToNetVector, playerToLeftAntennaVector, Vector3.DOWN)
	var angleToRightAntenna = Maths.SignedAngle(playerToNetVector, playerToRightAntennaVector, Vector3.DOWN)
	Console.AddNewLine(str("%.1f" % rad_to_deg(angleToLeftAntenna)) + " degrees to left antenna")
	Console.AddNewLine(str("%.1f" % rad_to_deg(angleToRightAntenna)) + " degrees to right antenna")
	
	Console.AddNewLine("Choosing an angle between the two", Color.LIME_GREEN)

#	if athlete.FrontCourt():
#		athlete.ball.attackTarget = athlete.team.CheckIfFlipped(Vector3(-randf_range(1, 9), 0, -4.5 + randf_range(0, 9)))
#	else:
#		athlete.ball.attackTarget = athlete.team.CheckIfFlipped(Vector3(-randf_range(6, 9), 0, -4.5 + randf_range(0, 9)))
	
	var lineCross = randf()
	var spikeAngleTopDown = lerp(angleToLeftAntenna, angleToRightAntenna, lineCross)
#	spikeAngleTopDown = PI/4
	Console.AddNewLine(str("%.1f" % rad_to_deg(spikeAngleTopDown)) + " potential spike angle")
	
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
	var topspin = 7.0
	
	var lowestNetPass = Vector3(0, 2.43 + 0.35, b)
#	athlete.team.mManager.cylinder.position = lowestNetPass
	var lowestPossibleSpike = Maths.FindParabolaForGivenSpeed(athlete.setRequest.target, lowestNetPass, u, false, topspin)

	var closestPossibleSpikeTarget:Vector3 = Maths.BallPositionAtGivenHeight(athlete.setRequest.target, lowestPossibleSpike, 0, topspin)
	
	var spikeDepth:float = randf_range(0.03, .97)
	athlete.ball.attackTarget = closestPossibleSpikeTarget

	if -athlete.team.flip * furthestCourtPoint.x > -athlete.team.flip * closestPossibleSpikeTarget.x:
		if closestPossibleSpikeTarget.z > -4.5 && closestPossibleSpikeTarget.z < 4.5:
			athlete.ball.attackTarget = lerp(closestPossibleSpikeTarget, furthestCourtPoint, spikeDepth)
	
	athlete.team.mManager.sphere.position = closestPossibleSpikeTarget
	athlete.team.mManager.cube.position = athlete.ball.attackTarget
	athlete.team.mManager.cylinder.position = furthestCourtPoint

#	athlete.ball.attackTarget = Maths.XZVector(lerp(athlete.ball.FindNetPass(), furthestCourtPoint, spikeDepth))

#	athlete.team.mManager.cylinder.position = Maths.XZVector(athlete.setRequest.target)
#	athlete.team.mManager.cube.position = Maths.XZVector(athlete.setRequest.target) + topDownSpikeVector
#	Console.AddNewLine(str("%.1f" % baselineZIntercept) + " baseline z intercept")
	
	var longestPossibleSpikeXZDistance = Maths.XZVector(athlete.setRequest.target).distance_to(furthestCourtPoint)
#	Console.AddNewLine(str("%.1f" % longestPossibleSpikeXZDistance) + " max possible spike distance")
	
	
	# What is their preference as to hitting line or cross? 
	# How aggressively will they swing? 
	Console.AddNewLine("End choice of initial spiking plan", Color.TOMATO)
	Console.AddNewLine("_____________________________________________________________", Color.TOMATO)
	
func ReadBlock(athlete:Athlete, otherTeam:Team):
	var ball = athlete.ball
	Console.AddNewLine("Reading block")
	var blockMaximumHeight:float = 0
	var ballRadius:float = 0.13
	var opposingBlockers:Array = []
	for potentialBlocker in otherTeam.courtPlayers:
		if potentialBlocker.FrontCourt() && potentialBlocker.blockState.blockingTarget == athlete:
			opposingBlockers.append(potentialBlocker)
			if potentialBlocker.stats.blockHeight > blockMaximumHeight:
				blockMaximumHeight = potentialBlocker.stats.blockHeight
	
	Console.AddNewLine("There are " + str(opposingBlockers.size()) + " blocker(s) to contend with")
	for i in range (opposingBlockers.size()):
		Console.AddNewLine(str(i + 1) + ": " + opposingBlockers[i].stats.lastName + " || " + str("%.0f"%(opposingBlockers[i].stats.blockHeight * 100)))
	
	
	# Will the block unify into a double or triple, or will there be a big seam? 
	var timeTillSpike = Maths.TimeTillBallReachesHeight(ball.position, ball.linear_velocity, athlete.stats.spikeHeight, 1.0)
	
	# The block has no seam/minimal seam if the blockers can get to within 0.75 of each other
	
	# Who is the blocker that will set the block position? 
	# If the ball is in the left third, their right, middle third: their middle obviously, ect
	var mainBlocker:Athlete
	var timeDelay = 0.05
	if athlete.setRequest.target.z * athlete.team.flip > 1.5:
		Console.AddNewLine("Set will be on the left from the team's perspective")
		mainBlocker = otherTeam.defendState.rightSideBlocker
		# Can they execute perfectly?
		var rightBlockerTime = mainBlocker.moveTarget.distance_to(mainBlocker.position) / mainBlocker.stats.speed + mainBlocker.blockState.timeTillBlockPeak
		
		if rightBlockerTime <= timeTillSpike + timeDelay:
			Console.AddNewLine("Other team's right blocker will be in position")
		
		var theirMiddle = otherTeam.defendState.middleBlocker
		if theirMiddle.blockState.blockingTarget == athlete:
			var middleBlockerTime = theirMiddle.moveTarget.distance_to(theirMiddle.position) / theirMiddle.stats.speed + theirMiddle.blockState.timeTillBlockPeak
			if middleBlockerTime <= timeTillSpike + timeDelay:
				Console.AddNewLine("Other team's middle will make a double block")
			else:
				Console.AddNewLine("Other team's middle will try to help, but won't close the seam")
		else:
			Console.AddNewLine("Middle not targetting spiker, nor should the left blocker really...")
			
		var theirLeft = otherTeam.defendState.leftSideBlocker
		if theirLeft.blockState.blockingTarget == athlete:
			var leftBlockerTime = theirLeft.moveTarget.distance_to(theirLeft.position) / theirLeft.stats.speed + theirLeft.blockState.timeTillBlockPeak
			if leftBlockerTime <= timeTillSpike + timeDelay:
				Console.AddNewLine("Other team's left blocker will make a triple block")
			else:
				Console.AddNewLine("Other team's left blocker will try to help, but won't close the seam")
				
	elif athlete.setRequest.target.z * athlete.team.flip > -1.5:
		mainBlocker = otherTeam.defendState.middleBlocker
	else:
		mainBlocker = otherTeam.defendState.leftSideBlocker
	
	if mainBlocker in opposingBlockers:
#		Console.AddNewLine("The relevant blocker will be present", Color.PEACH_PUFF)
		# We don't really know where the main blocker will set up their jump from
		# But just assume for now
		
		# Also assume effective block coverage is 2/3 of the height of the player
		var mainBlockerLeftBlockCoverageLimit = mainBlocker.position.z + athlete.team.flip * athlete.stats.height/3
		var mainBlockerRightBlockCoverageLimit = mainBlocker.position.z - athlete.team.flip * athlete.stats.height/3
	
		Console.AddNewLine("Left main block coverage limit: " + str(mainBlockerLeftBlockCoverageLimit), Color.PEACH_PUFF)
		Console.AddNewLine("Right main block coverage limit: " + str(mainBlockerRightBlockCoverageLimit), Color.PEACH_PUFF)
		var playerToNetVector = Vector3(-athlete.setRequest.target.x, 0, 0)
		var playerToLeftBlockLimitVector = Vector3(-athlete.setRequest.target.x, 0, athlete.team.flip * mainBlockerLeftBlockCoverageLimit - athlete.setRequest.target.z)
		var playerToRightBlockLimitVector = Vector3(-athlete.setRequest.target.x, 0, athlete.team.flip * mainBlockerRightBlockCoverageLimit - athlete.setRequest.target.z)
		
		var angleToLeftBlockLimit = Maths.SignedAngle(playerToNetVector, playerToLeftBlockLimitVector, Vector3.DOWN)
		var angleToRightBlockLimit = Maths.SignedAngle(playerToNetVector, playerToRightBlockLimitVector, Vector3.DOWN)
		Console.AddNewLine(str("%.1f" % rad_to_deg(angleToLeftBlockLimit)) + " degrees to left block limit")
		Console.AddNewLine(str("%.1f" % rad_to_deg(angleToRightBlockLimit)) + " degrees to right block limit")
		
#		athlete.team.mManager.cube.position = Vector3(0, mainBlocker.stats.blockHeight, mainBlockerLeftBlockCoverageLimit)
#		athlete.team.mManager.sphere.position = Vector3(0, mainBlocker.stats.blockHeight, mainBlockerRightBlockCoverageLimit)
	
	
	
	if athlete.stats.spikeHeight - ballRadius > blockMaximumHeight:
		Console.AddNewLine("Spiker will OTT block")
	
func ReadDefence(athlete:Athlete, otherTeam:Team):
	Console.AddNewLine("Reading defence " + athlete.stats.lastName + " " + otherTeam.teamName)
	
func CalculateTimeTillSpike(athlete:Athlete):
	var timeToGround:float = 0
	var timeToRunupStart:float = 0
	var runupTime:float = 0
	var jumpTime:float
	
	if athlete.stateMachine.currentState != self:
		if !athlete.rb.freeze && athlete.position.y > 0:
			timeToGround = Maths.TimeTillBallReachesHeight(athlete.position, athlete.linear_velocity, 0, 1.0)

	if spikeState == SpikeState.ChoiceConfirmed || spikeState == SpikeState.NotSpiking:
		if runupStartPosition:
			timeToRunupStart = Maths.XZVector(athlete.position).distance_to(runupStartPosition) / athlete.stats.speed
			runupTime = runupStartPosition.distance_to(takeOffXZ) / athlete.stats.speed
		
	if spikeState == SpikeState.Runup:
		runupTime = Maths.XZVector(athlete.position).distance_to(takeOffXZ) / athlete.stats.speed
	
	if spikeState == SpikeState.Jump:
		if athlete.linear_velocity.y < 0:
			jumpTime = -athlete.linear_velocity.y / athlete.g
		else:
			jumpTime = 0
	else:
		jumpTime = Maths.TimeTillBallReachesHeight(Vector3.UP * athlete.stats.verticalJump, Vector3.ZERO, 0, 1.0)
		
	var a = timeToGround + timeToRunupStart + runupTime + jumpTime
#	Console.AddNewLine(str(a))
	return a
