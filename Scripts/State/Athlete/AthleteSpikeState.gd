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
			if athlete.team.flip * athlete.position.x <= abs(takeOffXZ.x + athlete.team.flip * 0.1): #Maths.XZVector(takeOffXZ - athlete.position).length() < 0.1:
				spikeState = SpikeState.Jump
				athlete.rightIK.start()
				athlete.rightIK.interpolation = 1
				if athlete.rb.freeze:
					athlete.rb.freeze = false
					athlete.rb.gravity_scale = 1
					# We want to contact the ball at our max height...
					# This means a steeper jump for more extreme verticals
					athlete.rb.linear_velocity = athlete.team.ball.FindWellBehavedParabola(athlete.position, landingXZ, athlete.stats.verticalJump)
					if athlete == athlete.team.chosenSpiker:
						Console.AddNewLine("Chosen spiker " + athlete.stats.lastName + " thinks about how to spike the ball", Color.TOMATO)
						Console.AddNewLine("They plan to do [x]...", Color.TOMATO)
						# Is the set good enough to do everything the spiker wants to do? 
						# What is their guess as to the block they will face? 
						# What is their preference as to hitting line or cross? 
						# How aggressively will they swing? 
						
		SpikeState.Jump:
			athlete.rightIKTarget.global_transform.origin = athlete.team.ball.position

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
	athlete.rightIK.stop()
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
			setTime = distanceFactor * athlete.ball.SetTimeDownwardsParabola(athlete.team.receptionTarget, athlete.setRequest.target) 
		else:
			setTime = athlete.ball.SetTimeDownwardsParabola(athlete.team.receptionTarget, athlete.setRequest.target)
		
	else:
		# Standard set
		yVel = sqrt(2 * athlete.g * abs(athlete.setRequest.height - athlete.team.receptionTarget.y))
		if athlete.team.stateMachine.currentState == athlete.team.spikeState:
			var distanceFactor:float = 1 - Vector3(athlete.ball.position.x, 0, athlete.ball.position.z).distance_to(Maths.XZVector(athlete.team.receptionTarget))/ (Maths.XZVector(athlete.team.receptionTarget).distance_to(Maths.XZVector(athlete.setRequest.target)))
			setTime = distanceFactor * (yVel / athlete.g + sqrt(2 * athlete.g * abs(athlete.setRequest.height - athlete.setRequest.target.y)) / athlete.g)
		else:
			setTime = yVel / athlete.g + sqrt(2 * athlete.g * abs(athlete.setRequest.height - athlete.setRequest.target.y)) / athlete.g
		
	return athlete.team.timeTillDigTarget + setTime
