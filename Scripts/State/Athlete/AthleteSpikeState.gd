extends "res://Scripts/State/AthleteState.gd"
class_name AthleteSpikeState
const Enums = preload("res://Scripts/World/Enums.gd")

enum SpikeState {
NotSpiking,
ChoiceConfirmed,
Runup,
Jump
}
var customTopspin:float = 1
const ballRadius = 0.13 + .05

var takeOffXZ:Vector3
var landingXZ:Vector3
var timeTillJumpPeak
var spikeState = SpikeState.NotSpiking
#var athlete:Athlete
var spikeValue:float = 0
var runupStartPosition:Vector3

var oppositionLeftBlocker:Athlete
var oppositionMiddleBlocker:Athlete
var oppositionRightBlocker:Athlete

var leftBlockerLeftCoverage
var leftBlockerRightCoverage
var angleToRightLeft:float
var angleToRightRight:float

var middleBlockerLeftCoverage
var middleBlockerRightCoverage
var angleToMiddleLeft:float
var angleToMiddleRight:float

var rightBlockerLeftCoverage
var rightBlockerRightCoverage
var angleToLeftLeft:float
var angleToLeftRight:float

var leftOverlap:bool
var rightOverlap:bool

func Enter(athlete:Athlete):
	athlete.debug1.position.y = athlete.position.y + athlete.stats.height * 1.25
	athlete.animTree.set("parameters/state/transition_request", "moving")
	nameOfState="Spike"
	if !athlete.setRequest:
		print(athlete.stats.lastName + ": " + Enums.Role.keys()[athlete.stats.role])
		athlete.setRequest = athlete.middleSpikes[0]
	CalculateTakeOffXZ(athlete)
	spikeState = SpikeState.ChoiceConfirmed

func Update(athlete:Athlete):
	#if athlete.team.flip == 1 && athlete.stats.rotationPosition == 2:
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
					# This means a steeper jurightIKmp for more extreme verticals
					athlete.rb.linear_velocity = Maths.FindWellBehavedParabola(athlete.position, landingXZ, athlete.stats.verticalJump)
					if athlete == athlete.team.chosenSpiker:
						ChooseSpikingStrategy(athlete)

		SpikeState.Jump:
			if athlete.ball && athlete.ball.position:
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
			#if athlete == athlete.team.middleFront:
				#Console.AddNewLine("middle set time(1) " + str(setTime))
		else:
			setTime = Maths.SetTimeDownwardsParabola(athlete.team.receptionTarget, athlete.setRequest.target)
			#if athlete == athlete.team.middleFront:
				#Console.AddNewLine("middle set time(2) " + str(setTime), Color.WEB_PURPLE)
				#Console.AddNewLine("middle set vel(2) " + str(Maths.FindDownwardsParabola(athlete.team.receptionTarget, athlete.setRequest.target).length()), Color.WEB_PURPLE)

	else:
		# Standard set
		yVel = sqrt(2 * athlete.g * abs(athlete.setRequest.height - athlete.team.receptionTarget.y))
		if athlete.team.stateMachine.currentState == athlete.team.spikeState:
			var distanceFactor:float = 1 - Vector3(athlete.ball.position.x, 0, athlete.ball.position.z).distance_to(Maths.XZVector(athlete.team.receptionTarget))/ (Maths.XZVector(athlete.team.receptionTarget).distance_to(Maths.XZVector(athlete.setRequest.target)))
			setTime = distanceFactor * (yVel / athlete.g + sqrt(2 * athlete.g * abs(athlete.setRequest.height - athlete.setRequest.target.y)) / athlete.g)
		else:
			setTime = yVel / athlete.g + sqrt(2 * athlete.g * abs(athlete.setRequest.height - athlete.setRequest.target.y)) / athlete.g
	#if athlete == athlete.team.middleFront:
		#Console.AddNewLine(athlete.stats.lastName + " pred spike time(middle) " + str(athlete.team.timeTillDigTarget + setTime))

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

	var spikeAngles = []

	Console.AddNewLine(str("%.1f" % rad_to_deg(angleToLeftAntenna)) + " degrees to left antenna", Color.PLUM)

	if oppositionRightBlocker.stateMachine.currentState == oppositionRightBlocker.blockState:
		Console.AddNewLine(str("%.1f" % rad_to_deg(angleToRightRight)) + " degrees to [their perspective] right blocker right hand", Color.PLUM)
		Console.AddNewLine(str("%.1f" % rad_to_deg(angleToRightLeft)) + " degrees to [their perspective] right blocker left hand", Color.PLUM)
		if angleToLeftAntenna < angleToRightRight:
			spikeAngles.append([angleToLeftAntenna, angleToRightRight])
			Console.AddNewLine("Adding their right blocker")
		else:
			Console.AddNewLine("Not adding their right blocker because they cover the line")
	else:
		Console.AddNewLine("Apparently opposition right blocker not blocking", Color.PLUM)

	if oppositionMiddleBlocker.stateMachine.currentState == oppositionMiddleBlocker.blockState:
		Console.AddNewLine(str("%.1f" % rad_to_deg(angleToMiddleRight)) + " degrees to middle blocker right hand", Color.PLUM)
		Console.AddNewLine(str("%.1f" % rad_to_deg(angleToMiddleLeft)) + " degrees to middle blocker left hand", Color.PLUM)
		if spikeAngles.size() == 0:
			Console.AddNewLine("No spike angle between their right blocker and the antenna")
			if oppositionRightBlocker.stateMachine.currentState == oppositionRightBlocker.blockState:
				Console.AddNewLine("Opposition right blocker completely covers line")
				if angleToRightLeft < angleToMiddleRight:
					Console.AddNewLine("Adding middle, seam to opposition right blocker")
				else:
					Console.AddNewLine("Overlap between middle and opposition right blocker, double at least...")
			else:
				if angleToLeftAntenna < angleToMiddleRight:
					spikeAngles.append([angleToLeftAntenna, angleToMiddleRight])
					Console.AddNewLine("Adding middle, opposition right not blocking")
		else:
			Console.AddNewLine("1 spike angle already")
			if angleToRightLeft < angleToMiddleRight:
				spikeAngles.append([angleToRightLeft, angleToMiddleRight])
				Console.AddNewLine("Adding middle, seam to opposition right blocker")
			else:
				Console.AddNewLine("Overlap between middle and opposition right blocker, double at least...")

	else:
		Console.AddNewLine("Apparently opposition middle blocker not blocking", Color.PLUM)

	if oppositionLeftBlocker.stateMachine.currentState == oppositionLeftBlocker.blockState:
		Console.AddNewLine(str("%.1f" % rad_to_deg(angleToLeftRight)) + " degrees to [their perspective] left blocker right hand", Color.PLUM)
		Console.AddNewLine(str("%.1f" % rad_to_deg(angleToLeftLeft)) + " degrees to [their perspective] left blocker left hand", Color.PLUM)
		if spikeAngles.size() == 0:
			Console.AddNewLine("No spike angles")
			# could be:  other two aren't blocking,
			# the other 2 are doing a double with line closed and you've got a seam,
			# or a triple with the line shut off
			# or line is shut off but middle isn't blocking
			if oppositionRightBlocker.stateMachine.currentState != oppositionRightBlocker.blockState && oppositionMiddleBlocker.stateMachine.currentState != oppositionMiddleBlocker.blockState:
				Console.AddNewLine("No other blockers, opposition left blocker will cover the whole lot")
				if angleToLeftAntenna < angleToLeftRight:
					Console.AddNewLine("Adding opposiion left blocker")
					spikeAngles.append([angleToLeftAntenna, angleToLeftRight])
				if angleToLeftLeft < angleToRightAntenna:
					Console.AddNewLine("Adding left blocker to right antenna")
					spikeAngles.append([angleToLeftLeft, angleToRightAntenna])
				else:
					Console.AddNewLine("Left blocker closes off line")


			if oppositionMiddleBlocker.stateMachine.currentState != oppositionMiddleBlocker.blockState:
				Console.AddNewLine("No middle blocker but line closed by right blocker")
				if angleToRightLeft < angleToLeftRight:
					spikeAngles.append([angleToRightLeft, angleToLeftRight])
					Console.AddNewLine("Adding left blocker")
				else:
					Console.AddNewLine("No seam between left and middle")
				if angleToLeftLeft < angleToRightAntenna:
					Console.AddNewLine("Adding left blocker to right antenna")
					spikeAngles.append([angleToLeftLeft, angleToRightAntenna])
				else:
					Console.AddNewLine("Left blocker closes off line")

			else:
				Console.AddNewLine("Line is closed, and there is no seam between right and middle")
				if angleToMiddleLeft < angleToLeftRight:
					spikeAngles.append([angleToMiddleLeft, angleToLeftRight])
					Console.AddNewLine("Adding left blocker seam to middle")
				else:
					Console.AddNewLine("No seam between left and middle")
				if angleToLeftLeft < angleToRightAntenna:
					Console.AddNewLine("Adding left blocker to right antenna")
					spikeAngles.append([angleToLeftLeft, angleToRightAntenna])
				else:
					Console.AddNewLine("Left blocker closes off line")

		elif spikeAngles.size() == 1:
			Console.AddNewLine("1 block-free spike angle so far")
			if spikeAngles[0][1] == angleToRightRight:
				Console.AddNewLine("There is line on the right side open")
				if angleToMiddleLeft < angleToLeftRight:
					spikeAngles.append([angleToMiddleLeft, angleToLeftRight])
					Console.AddNewLine("Adding left blocker seam to middle")
				else:
					Console.AddNewLine("No seam between left and middle")
				if angleToLeftLeft < angleToRightAntenna:
					Console.AddNewLine("Adding left blocker to right antenna")
					spikeAngles.append([angleToLeftLeft, angleToRightAntenna])
				else:
					Console.AddNewLine("Left blocker closes off line")
			else:
				# Middle must be blocking with a seam to right, or they aren't in the block.
				Console.AddNewLine("Line is not open on the right", Color.PLUM)
				if angleToMiddleLeft < angleToLeftRight:
					spikeAngles.append([angleToMiddleLeft, angleToLeftRight])
					Console.AddNewLine("Adding left blocker seam to middle")
				else:
					Console.AddNewLine("No seam between left and middle")
				if angleToLeftLeft < angleToRightAntenna:
					Console.AddNewLine("Adding left blocker to right antenna")
					spikeAngles.append([angleToLeftLeft, angleToRightAntenna])
				else:
					Console.AddNewLine("Left blocker closes off line")
		else:
			Console.AddNewLine("2 block-free spike angles so far")
			if angleToMiddleLeft < angleToLeftRight:
				spikeAngles.append([angleToMiddleLeft, angleToLeftRight])
				Console.AddNewLine("Adding left blocker seam to middle")
			else:
				Console.AddNewLine("No seam between left and middle")
			if angleToLeftLeft < angleToRightAntenna:
				Console.AddNewLine("Adding left blocker to right antenna")
				spikeAngles.append([angleToLeftLeft, angleToRightAntenna])
			else:
				Console.AddNewLine("Left blocker closes off line")

	else:
		Console.AddNewLine("Apparently opposition left blocker not blocking", Color.PLUM)
		if oppositionMiddleBlocker.stateMachine.currentState == oppositionMiddleBlocker.blockState:
			if angleToMiddleLeft < angleToRightAntenna:
				Console.AddNewLine("Adding middle to antenna seam")
				spikeAngles.append([angleToMiddleLeft, angleToRightAntenna])
			else:
				Console.AddNewLine("Middle covers line... what a huge lad")
		elif oppositionRightBlocker.stateMachine.currentState == oppositionRightBlocker.blockState:
			if angleToRightLeft < angleToRightAntenna:
				Console.AddNewLine("Adding right to far antenna seam")
				spikeAngles.append([angleToRightLeft, angleToRightAntenna])
			else:
				Console.AddNewLine("Right covers line on the other side... immense")
		else:
			Console.AddNewLine("No block, adding whole net")
			spikeAngles.append([angleToLeftAntenna, angleToRightAntenna])

	for pair in spikeAngles:
		Console.AddNewLine("Spike angle: " + str("%.1f" % rad_to_deg(pair[0])) + " " + str("%.1f" % rad_to_deg(pair[1])), Color.PLUM)
	if spikeAngles.size() == 0:
		Console.AddNewLine("No possible spike angles, must be some lanky blockers...", Color.PLUM)
	Console.AddNewLine(str("%.1f" % rad_to_deg(angleToRightAntenna)) + " degrees to right antenna", Color.PLUM)

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

	#FindPermissableAnglesDisregardingBlock(athlete)
	var playerToLeftCornerVector = Vector3(-athlete.setRequest.target.x - athlete.team.flip * 9, 0, -athlete.setRequest.target.z + athlete.team.flip * 4.5)
	var playerToRightCornerVector = Vector3(-athlete.setRequest.target.x - athlete.team.flip * 9, 0, -athlete.setRequest.target.z - athlete.team.flip * 4.5)
	#athlete.team.mManager.cube.position = Maths.XZVector(athlete.setRequest.target) + playerToRightCornerVector #Vector3(athlete.team.flip * -9, 0, athlete.team.flip * 4.5)
	var angleToLeftCorner = Maths.SignedAngle(playerToNetVector, playerToLeftCornerVector, Vector3.DOWN)
	var angleToRightCorner = Maths.SignedAngle(playerToNetVector, playerToRightCornerVector, Vector3.DOWN)

	### Now we need to make a list of angles to test whether the ball will go in along. Binary search.

	#FindPermissableAnglesDisregardingBlock(athlete)

	var spikeAngleTopDown
	var lineCross = randf()

	var canSpikeToLeftCorner:bool = WillBallSpikedOnAngleLandIn(athlete.setRequest.target, 100.0/3.6, angleToLeftCorner, athlete.team.flip, customTopspin)
	if !canSpikeToLeftCorner:
		Console.AddNewLine("Can't spike to left corner", Color.OLIVE_DRAB)
	var canSpikeToRightCorner:bool = WillBallSpikedOnAngleLandIn(athlete.setRequest.target, 100.0/3.6, angleToLeftCorner, athlete.team.flip, customTopspin)
	if !canSpikeToRightCorner:
		Console.AddNewLine("Can't spike to right corner", Color.OLIVE_DRAB)
	if !canSpikeToLeftCorner && !canSpikeToRightCorner:
		Console.AddNewLine("Can't spike at all from this position :(", Color.OLIVE_DRAB)
		# Choose another option from our exciting menu of attacking options...



	Console.AddNewLine(str(spikeAngles.size()) + " possible spike angles", Color.DEEP_SKY_BLUE)
	var revisedSpikeableAngles:Array = []
	for i:int in range(spikeAngles.size()):
		# For each spike angle, we need to see if it includes the angle to the corners
		# If it does, we need to split into two more angles, as the idea is to move along the court
		# lines to see if it's spikeable.

		# We want to find the bounds of spikeablility. So we need to test both limits of our
		# possibly newly split intervals. If they're both good we're hunky dory.

		# If one is, we need to step using a binary method to find the angle at which the spike will
		# clip the line.



		if spikeAngles[i][0] < angleToLeftCorner && spikeAngles[i][1] > angleToRightCorner:
			var x
			# Large area open, need to split 3 ways.
		elif spikeAngles[i][0] < angleToLeftCorner && spikeAngles[i][1] > angleToLeftCorner:
			# left corner is in the middle.
			var x
		elif spikeAngles[i][0] < angleToRightCorner && spikeAngles[i][1] > angleToRightCorner:
			# right corner is in the middle.
			var x
		else:
			var x
			# Presumably most of the time we'll end up here with no adjustments.



	# Choose a spike angle

	if spikeAngles.size() > 0:
		var choice = randi()%spikeAngles.size()
		spikeAngleTopDown = lerp(spikeAngles[choice][0], spikeAngles[choice][1], lineCross)


	else:
		assert(false)
		spikeAngleTopDown = lerp(angleToLeftCorner, angleToRightCorner, lineCross)
#	spikeAngleTopDown = PI/4
#	Console.AddNewLine(str("%.1f" % rad_angleToRightCornerto_deg(spikeAngleTopDown)) + " potential spike angle")

	var yes = WillBallSpikedOnAngleLandIn(athlete.setRequest.target, 100.0/3.6, spikeAngleTopDown, athlete.team.flip, customTopspin)

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
#	Console.AddNewLine(str("%.1f" % baselineZIntercept) + " baseline z intercept")
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

	athlete.team.mManager.cube.position = furthestCourtPoint
	var u = 100.0/3.6


	var lowestNetPass = Vector3(0, 2.43 + ballRadius, b)
#	athlete.team.mManager.cylinder.position = lowestNetPass
	var lowestPossibleSpike = Maths.FindParabolaForGivenSpeed(athlete.setRequest.target, lowestNetPass, u, false, customTopspin)
	if lowestPossibleSpike == null:
		Console.AddNewLine("Lowest possible spike turned out to not be possible after all. How embarrassing!")
		lowestPossibleSpike = Vector3.ZERO
		athlete.team.mManager.Pause()
	var closestPossibleSpikeTarget:Vector3 = Maths.BallPositionAtGivenHeight(athlete.setRequest.target, lowestPossibleSpike, ballRadius, customTopspin)

	athlete.ball.attackTarget = closestPossibleSpikeTarget
	athlete.team.mManager.sphere.position = closestPossibleSpikeTarget
	athlete.team.mManager.cylinder.position = Maths.BallPositionAtGivenHeight(athlete.setRequest.target, lowestPossibleSpike, 0, customTopspin)



	var landingIn:bool = false
# if the furthest point is closer than the edge of the court, choose some depth randomly (for now)
	if -athlete.team.flip * furthestCourtPoint.x > -athlete.team.flip * closestPossibleSpikeTarget.x:
		if closestPossibleSpikeTarget.z > -4.5 && closestPossibleSpikeTarget.z < 4.5:
			landingIn = true
			var spikeDepth:float = randf_range(0.03, .97)
			#athlete.ball.attackTarget = lerp(closestPossibleSpikeTarget, furthestCourtPoint, spikeDepth)

	# Otherwise though, it's just flying long...
	if !landingIn:
		Console.AddNewLine("Spike landing out :(")
		ball.attackTarget = furthestCourtPoint
	var vel = Maths.FindParabolaForGivenSpeed(athlete.setRequest.target, ball.attackTarget, u, false, 3.0)
	if vel == null:
		Console.AddNewLine("ERROR, impossible parabola requested")
		vel = Vector3.ZERO
	#athlete.team.mManager.cylinder.position = Maths.FindNetPass(athlete.setRequest.target, ball.attackTarget, vel, 3.0)
#	Console.AddNewLine("Predicted net pass: " + str(athlete.team.mManager.cylinder.position))
	#var longestPossibleSpikeXZDistance = Maths.XZVector(athlete.setRequest.target).distance_to(furthestCourtPoint)
#	Console.AddNewLine(str("%.1f" % longestPossibleSpikeXZDistance) + " max possible spike distance")




	# What is their preference as to hitting line or cross?
	# How aggressively will they swing?
	Console.AddNewLine("End choice of initial spiking plan", Color.TOMATO)
	Console.AddNewLine("_____________________________________________________________", Color.TOMATO)

func ReadBlock(athlete:Athlete, otherTeam:TeamNode):
	var ball = athlete.ball
	Console.AddNewLine("Reading block")

	oppositionLeftBlocker = otherTeam.defendState.leftSideBlocker
	oppositionMiddleBlocker = otherTeam.defendState.middleBlocker
	oppositionRightBlocker = otherTeam.defendState.rightSideBlocker


	var leftBlockerPossiblePosition
	var middleBlockerPossiblePosition
	var rightBlockerPossiblePosition

	#ProduceOTTReport(athlete, oppositionLeftBlocker, oppositionMiddleBlocker, oppositionRightBlocker)

	var timeTillSpikeContact = Maths.TimeTillBallReachesHeight(ball.position, ball.linear_velocity, athlete.stats.spikeHeight, 1.0)
	# before I forget this - seems to always trigger when a non-setter standing sets the middle
	if is_nan(timeTillSpikeContact):
		Console.AddNewLine("Can't find time till spike contact", Color.CORNFLOWER_BLUE)
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
			if is_nan(moveDistance):
				moveDistance = 0
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
				Console.AddNewLine("Opposition middle has already jumped", Color.BLUE)
				middleLandingTime = Maths.TimeTillBallReachesHeight(oppositionMiddleBlocker.position, oppositionMiddleBlocker.linear_velocity, 0, 1.0)

			if timeTillSpikeContact < oppositionMiddleBlocker.blockState.jumpTime + middleLandingTime:
				# The middle has already jumped, or won't land in time to jump again
				middleBlockerPossiblePosition = oppositionMiddleBlocker.position

				middleBlockerLeftCoverage = oppositionMiddleBlocker.position.z - athlete.team.flip * oppositionMiddleBlocker.stats.height/3
				middleBlockerRightCoverage = oppositionMiddleBlocker.position.z + athlete.team.flip * oppositionMiddleBlocker.stats.height/3

			else:
				var moveTime = timeTillSpikeContact - oppositionMiddleBlocker.blockState.jumpTime - middleLandingTime
				var moveDistance = oppositionMiddleBlocker.stats.speed * moveTime
				if is_nan(moveDistance):
					moveDistance = 0

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
					if is_nan(moveDistance):
						moveDistance = 0

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
				if is_nan(moveDistance):
					moveDistance = 0

				middleBlockerPossiblePosition = oppositionMiddleBlocker.position + moveDistance * (oppositionMiddleBlocker.moveTarget - Maths.XZVector(oppositionMiddleBlocker.position)).normalized()

				middleBlockerLeftCoverage = middleBlockerPossiblePosition.z - athlete.team.flip * oppositionMiddleBlocker.stats.height/3
				middleBlockerRightCoverage = middleBlockerPossiblePosition.z + athlete.team.flip * oppositionMiddleBlocker.stats.height/3

		# Can the left blocker get over?
		if oppositionLeftBlocker.rb.freeze:
			var moveTime = timeTillSpikeContact - oppositionLeftBlocker.blockState.jumpTime
			var moveDistance = oppositionLeftBlocker.stats.speed * moveTime
			if is_nan(moveDistance):
				moveDistance = 0

			leftBlockerPossiblePosition = oppositionLeftBlocker.position + moveDistance * (oppositionLeftBlocker.moveTarget - Maths.XZVector(oppositionLeftBlocker.position)).normalized()

			leftBlockerLeftCoverage = leftBlockerPossiblePosition.z - athlete.team.flip * oppositionLeftBlocker.stats.height/3
			leftBlockerRightCoverage = leftBlockerPossiblePosition.z + athlete.team.flip * oppositionLeftBlocker.stats.height/3

		else:
			leftBlockerLeftCoverage = oppositionLeftBlocker.position.z - athlete.team.flip * oppositionLeftBlocker.stats.height/3
			leftBlockerRightCoverage = oppositionLeftBlocker.position.z + athlete.team.flip * oppositionLeftBlocker.stats.height/3

		if oppositionRightBlocker.rb.freeze:
			var moveTime = timeTillSpikeContact - oppositionRightBlocker.blockState.jumpTime
			var moveDistance = oppositionRightBlocker.stats.speed * moveTime
			if is_nan(moveDistance):
				moveDistance = 0
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
			if is_nan(moveDistance):
				moveDistance = 0

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
				if is_nan(moveDistance):
					moveDistance = 0

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
					if is_nan(moveDistance):
						moveDistance = 0

					rightBlockerPossiblePosition = oppositionRightBlocker.position + moveDistance * (oppositionRightBlocker.moveTarget - Maths.XZVector(oppositionRightBlocker.position)).normalized()

					rightBlockerLeftCoverage = rightBlockerPossiblePosition.z - athlete.team.flip * oppositionRightBlocker.stats.height/3
					rightBlockerRightCoverage = rightBlockerPossiblePosition.z + athlete.team.flip * oppositionRightBlocker.stats.height/3




	var playerToNetVector = Vector3(-athlete.setRequest.target.x, 0, 0)

	if !rightBlockerLeftCoverage:
		Console.AddNewLine("Couldn't see their right blocker, maybe you can though", Color.LIME_GREEN)
	else:
		var playerToRightLeft = Vector3(-athlete.setRequest.target.x, 0, rightBlockerLeftCoverage - athlete.setRequest.target.z)
		var playerToRightRight = Vector3(-athlete.setRequest.target.x, 0, rightBlockerRightCoverage - athlete.setRequest.target.z)
		if is_nan(rightBlockerLeftCoverage):
			var x
		angleToRightLeft = Maths.SignedAngle(playerToNetVector, playerToRightLeft, Vector3.DOWN)
		angleToRightRight = Maths.SignedAngle(playerToNetVector, playerToRightRight, Vector3.DOWN)

#		Console.AddNewLine(str("%.1f" % rad_to_deg(angleToRightRight)) + " degrees to (opposition perspective) right blocker right hand")
#		Console.AddNewLine(str("%.1f" % rad_to_deg(angleToRightLeft)) + " degrees to (opposition perspective) right blocker left hand")

	if !middleBlockerLeftCoverage:
		Console.AddNewLine("Couldn't see a middle block, maybe you can though", Color.LIME_GREEN) #might never be called
	elif is_nan(middleBlockerLeftCoverage):
		Console.AddNewLine("Don't mind this error, it's just the debug shapes not having a position", Color.RED)
	else:
		#athlete.team.mManager.cube.position = Vector3(0, oppositionMiddleBlocker.stats.blockHeight, middleBlockerLeftCoverage)
		#athlete.team.mManager.sphere.position = Vector3(0, oppositionMiddleBlocker.stats.blockHeight, middleBlockerRightCoverage)

		var playerToMiddleLeft = Vector3(-athlete.setRequest.target.x, 0, middleBlockerLeftCoverage - athlete.setRequest.target.z)
		var playerToMiddleRight = Vector3(-athlete.setRequest.target.x, 0, middleBlockerRightCoverage - athlete.setRequest.target.z)
		angleToMiddleLeft = Maths.SignedAngle(playerToNetVector, playerToMiddleLeft, Vector3.DOWN)
		angleToMiddleRight = Maths.SignedAngle(playerToNetVector, playerToMiddleRight, Vector3.DOWN)

#		Console.AddNewLine(str("%.1f" % rad_to_deg(angleToMiddleRight)) + " degrees to (opposition perspective) middle blocker right hand")
#		Console.AddNewLine(str("%.1f" % rad_to_deg(angleToMiddleLeft)) + " degrees to (opposition perspective) middle blocker left hand")


	if !leftBlockerLeftCoverage:
		Console.AddNewLine("Couldn't see their left blocker, maybe you can though", Color.LIME_GREEN)
	else:


		var playerToLeftLeft = Vector3(-athlete.setRequest.target.x, 0, leftBlockerLeftCoverage - athlete.setRequest.target.z)
		var playerToLeftRight = Vector3(-athlete.setRequest.target.x, 0, leftBlockerRightCoverage - athlete.setRequest.target.z)
		angleToLeftLeft = Maths.SignedAngle(playerToNetVector, playerToLeftLeft, Vector3.DOWN)
		angleToLeftRight = Maths.SignedAngle(playerToNetVector, playerToLeftRight, Vector3.DOWN)

#		Console.AddNewLine(str("%.1f" % rad_to_deg(angleToLeftRight)) + " degrees to (opposition perspective) left blocker right hand")
#		Console.AddNewLine(str("%.1f" % rad_to_deg(angleToLeftLeft)) + " degrees to (opposition perspective) left blocker left hand")




	var flip = athlete.team.flip
	leftOverlap = false
	rightOverlap = false

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

func ReadDefence(athlete:Athlete, otherTeam:TeamNode):
	Console.AddNewLine("Reading defence " + athlete.stats.lastName + " " + otherTeam.data.teamName)
	var defenders:Array = []
	for lad in otherTeam.courtPlayerNodes:
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

#func ProduceOTTReport(athlete:Athlete, oppositionLeftBlocker:Athlete, oppositionMiddleBlocker:Athlete, oppositionRightBlocker:Athlete):
	#pass

	#if thlete.stats.spikeHeight - ballRadius:

func FindPermissableAnglesDisregardingBlock(athlete:Athlete):
	# Technically should check if they are within range of the net...
	# IE not spiking from 20km back, or from under the net height by an unfeasible margin
	# Under net height will affect a key assumption that the lowest netpass is the best





	var flip = athlete.team.flip

	var contactPoint:Vector3 = athlete.setRequest.target
	var netPass:Vector3 = Vector3.ZERO
	var landingPoint:Vector3 = Vector3.ZERO

	var initialVelocityMagnitude:float = 100

	# First, does any corner spike land in?
	# To do this, I need the angle to the corner, which we have, and then the netpass, which can be worked
	# out, and finally the ball position when it touches the ground.

	# How does topspin fall into this? Same topspin every time? Yes, 3.0 is the amount

	var playerToNetVector = Vector3(-athlete.setRequest.target.x, 0, 0)

	var playerToLeftCornerVector = Vector3(-athlete.setRequest.target.x - athlete.team.flip * 9, 0, -athlete.setRequest.target.z + athlete.team.flip * 4.5)
	var playerToRightCornerVector = Vector3(-athlete.setRequest.target.x - athlete.team.flip * 9, 0, -athlete.setRequest.target.z - athlete.team.flip * 4.5)

	var angleToLeftCorner = Maths.SignedAngle(playerToNetVector, playerToLeftCornerVector, Vector3.DOWN)
	var angleToRightCorner = Maths.SignedAngle(playerToNetVector, playerToRightCornerVector, Vector3.DOWN)

# for left corner
	var leftCorner:Vector3 = Vector3(-athlete.team.flip * 9, 0, -athlete.team.flip * 4.5)
	var distanceFactor:float = contactPoint.x / (abs(contactPoint.x) + abs(leftCorner.x))
	if contactPoint.x < 0:
		distanceFactor *= -1;
	netPass = contactPoint + ( - contactPoint) * distanceFactor
	netPass.y = 2.43 + ballRadius


	landingPoint.x = -4.5 * flip


	var yDistBallToNetpass = contactPoint.y - netPass.y
	if yDistBallToNetpass < 0 :
		Console.AddNewLine("Warning: spiking from below net height")

	var testSpike = Maths.FindParabolaForGivenSpeed(contactPoint, netPass, 100.0/3.6, false, 3)
	var testLandingSpot = Maths.BallPositionAtGivenHeight(contactPoint, testSpike, 0, 3)

	if abs(testLandingSpot.x) > abs(leftCorner.x):
		Console.AddNewLine("ball will land out past the service line", Color.DARK_GOLDENROD)


	#var playerToNetVector = Vector3(-athlete.setRequest.target.x, 0, 0)
	var playerToLeftAntennaVector = Vector3(-athlete.setRequest.target.x, 0, athlete.team.flip * (4.5 - ballRadius) - athlete.setRequest.target.z)
	var playerToRightAntennaVector = Vector3(-athlete.setRequest.target.x, 0, athlete.team.flip * (-4.5 + ballRadius) - athlete.setRequest.target.z)

	var angleToLeftAntenna = Maths.SignedAngle(playerToNetVector, playerToLeftAntennaVector, Vector3.DOWN)
	var angleToRightAntenna = Maths.SignedAngle(playerToNetVector, playerToRightAntennaVector, Vector3.DOWN)

	var xzDistanceFromNetToLandingPoint

	var xLandingPosAtLeftSideline:float
	var xLandingPosAtRightSideline:float

	var zLandingPosAtBaseLine:float

	var initialVelocity = 100/3.6 # Good old 100kph spike
	var timeToNetPass:float


func WillBallSpikedOnAngleLandIn(contactPoint:Vector3, speed:float, angle:float, flip:float, topspin:float) -> bool:
	if contactPoint.y < 2.43 + ballRadius:
		return false

	# if angle doesn't cross the net, also false?

	var furthestCourtPoint:Vector3
	# Find the nearest intersection to the edge of the court along the line
	# of the angle to work out how long the spike can be
	var topDownSpikeVector:Vector3 = Vector3(-flip, 0, 0).rotated(Vector3.DOWN, angle)
#	Console.AddNewLine(str(topDownSpikeVector) + " spike vector")
	# Using our old friend y = mx + b (But with z as y)
	var m:float = topDownSpikeVector.z / topDownSpikeVector.x
#	Console.AddNewLine(str("%.1f" % m) + " m")
	var b:float = contactPoint.z - m * contactPoint.x
#	Console.AddNewLine(str("%.1f" % athlete.setRequest.target.z) + " set request z", Color.FUCHSIA)
#	Console.AddNewLine(str("%.1f" % athlete.setRequest.target.x) + " set request x", Color.FUCHSIA)
#	Console.AddNewLine(str("%.1f" % b) + " b")

	var baselineZIntercept:float = m * 9 * -flip + b
#	Console.AddNewLine(str("%.1f" % baselineZIntercept) + " baseline z intercept")
	# If the baseline intercept is wider than the antennae, the ball is out on the side first
	if abs(baselineZIntercept) > 4.5:
		var leftSideXIntercept:float = (4.5 - b)/m
		var rightSideXIntercept:float = (-4.5 - b)/m
#		Console.AddNewLine(str("%.1f" % leftSideXIntercept) + " left x intercept")
#		Console.AddNewLine(str("%.1f" % rightSideXIntercept) + " right x intercept")
		if sign(leftSideXIntercept) == sign(rightSideXIntercept):
			Console.AddNewLine("Ball trajectory doesn't cross net inside antennae")
		if sign(leftSideXIntercept) == flip:
			furthestCourtPoint = Vector3(rightSideXIntercept, 0, -4.5)
		else:
			furthestCourtPoint = Vector3(leftSideXIntercept, 0, 4.5)
	else:
		furthestCourtPoint = Vector3(9 * -flip, 0, baselineZIntercept)

	var lowestNetPass = Vector3(0, 2.43 + ballRadius, b)
#	athlete.team.mManager.cylinder.position = lowestNetPass
	var lowestPossibleSpike = Maths.FindParabolaForGivenSpeed(contactPoint, lowestNetPass, speed, false, topspin)
	if lowestPossibleSpike == null:
		Console.AddNewLine("Lowest possible spike turned out to not be possible after all. How embarrassing!")
		lowestPossibleSpike = Vector3.ZERO
		assert(false)
	var closestPossibleSpikeTarget:Vector3 = Maths.BallPositionAtGivenHeight(contactPoint, lowestPossibleSpike, ballRadius, topspin)

	if -flip * furthestCourtPoint.x > -flip * closestPossibleSpikeTarget.x:
		if closestPossibleSpikeTarget.z > -4.5 && closestPossibleSpikeTarget.z < 4.5:
			return true

	return false



#func BallPositionAfterLowestPossibleSpikeAndMostConvolutedFunctionNameGivenStartAndSomeZValue(initialSpeed:float, contactPoint:Vector3, zPos:float, netPassY:float) -> Vector3:
	## First find top down angle
	#var playerToNetVector:Vector3 = Vector3(-contactPoint.x, 0, 0)
	#var playerToDesiredZVector:Vector3 = Vector3()
#
#
	## Then find side on angle
	## Then the velocity
	## Then the ball pos at given z point
	#return Vector3.ZERO
