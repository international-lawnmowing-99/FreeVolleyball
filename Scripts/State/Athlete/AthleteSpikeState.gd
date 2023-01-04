extends "res://Scripts/State/AthleteState.gd"
const Enums = preload("res://Scripts/World/Enums.gd")

enum SpikeState {
NotSpiking,
ChoiceConfirmed,
Runup,
Jump
}
var takeOffXZ:Vector3
var timeTillJumpPeak
var spikeState = SpikeState.NotSpiking
var athlete:Athlete
var spikeValue:float = 0
var runupStartPosition:Vector3

func Enter(_athlete:Athlete):
	nameOfState="Spike"
	if !athlete.setRequest:
		print(athlete.stats.lastName + ": " + Enums.Role.keys()[athlete.role])
		athlete.setRequest = athlete.middleSpikes[0]
	takeOffXZ = Vector3(athlete.setRequest.target.x\
	 - athlete.team.flip * athlete.stats.verticalJump / 2, \
	0, athlete.setRequest.target.z)
#	athlete.CalculateTimeTillJumpPeak(takeOffXZ)
	spikeState = SpikeState.ChoiceConfirmed
	pass
func Update(_athlete:Athlete):
	#if athlete.team.flip == 1 && athlete.rotationPosition == 2:
		#print(spikeState)
	match spikeState:
		SpikeState.NotSpiking:
			pass
			
		SpikeState.ChoiceConfirmed:
			takeOffXZ = Vector3(athlete.setRequest.target.x + athlete.team.flip * athlete.stats.verticalJump / 2, \
			0, athlete.setRequest.target.z)
#			athlete.CalculateTimeTillJumpPeak(takeOffXZ)
	
			var timeTillBallReachesSetTarget:float 
			var setTime:float
			var yVel:float
			
			yVel = sqrt(2 * athlete.g * abs(athlete.setRequest.height - athlete.team.receptionTarget.y))
			
			if athlete.setRequest.height < athlete.team.receptionTarget.y:
				#yVel *= -1
				#UNTESTED!!!
				#yVel = sqrt(2 * athlete.g * (athlete.setRequest.height - athlete.team.receptionTarget.y))
				#Engine.time_scale = 0
				print("Setting downwards because you're such a unit")
				print("Errors inbound(?)")
				if athlete.team.stateMachine.currentState == athlete.team.spikeState:
					var distanceFactor:float = 1 - Vector3(athlete.ball.translation.x, 0, athlete.ball.translation.z).distance_to(athlete.team.xzVector(athlete.team.receptionTarget))/ (athlete.team.xzVector(athlete.team.receptionTarget).distance_to(athlete.team.xzVector(athlete.setRequest.target)))
					setTime = distanceFactor * (yVel / athlete.g + sqrt(2 * athlete.g * abs(athlete.setRequest.height - athlete.setRequest.target.y)) / athlete.g)
				else:
					setTime = yVel / athlete.g + sqrt(2 * athlete.g * abs(athlete.setRequest.height - athlete.setRequest.target.y)) / athlete.g
			else:
				# Standard set
				if athlete.team.stateMachine.currentState == athlete.team.spikeState:
					var distanceFactor:float = 1 - Vector3(athlete.ball.translation.x, 0, athlete.ball.translation.z).distance_to(athlete.team.xzVector(athlete.team.receptionTarget))/ (athlete.team.xzVector(athlete.team.receptionTarget).distance_to(athlete.team.xzVector(athlete.setRequest.target)))
					setTime = distanceFactor * (yVel / athlete.g + sqrt(2 * athlete.g * abs(athlete.setRequest.height - athlete.setRequest.target.y)) / athlete.g)
				else:
					setTime = yVel / athlete.g + sqrt(2 * athlete.g * abs(athlete.setRequest.height - athlete.setRequest.target.y)) / athlete.g
				
			timeTillBallReachesSetTarget = athlete.team.timeTillDigTarget + setTime
			
			if timeTillBallReachesSetTarget <= athlete.CalculateTimeTillJumpPeak(takeOffXZ) && athlete.team.stateMachine.currentState != athlete.team.receiveState:
				spikeState = SpikeState.Runup
				athlete.moveTarget = takeOffXZ
#				print(athlete.stats.lastName + " " + str(athlete.CalculateTimeTillJumpPeak(takeOffXZ)))
#				print(str(timeTillBallReachesSetTarget) + str(athlete.team.stateMachine.currentState))

		SpikeState.Runup:
			if athlete.team.xzVector(takeOffXZ - athlete.translation).length() < 0.1:
				spikeState = SpikeState.Jump

		SpikeState.Jump:
			if athlete.rb.mode == RigidBody.MODE_KINEMATIC:
				athlete.rb.mode = RigidBody.MODE_RIGID
				athlete.rb.gravity_scale = 1
				athlete.rb.linear_velocity = athlete.team.ball.FindWellBehavedParabola(athlete.translation, Vector3(athlete.setRequest.target.x, 0, athlete.setRequest.target.z), athlete.stats.verticalJump)

			if athlete.translation.y <= 0.05 && athlete.rb.linear_velocity.y < 0:
				athlete.rb.mode = RigidBody.MODE_KINEMATIC
				athlete.rb.gravity_scale = 0
				athlete.translation.y = 0
				athlete.moveTarget = athlete.translation
				#athlete.PrepareToDefend()
				spikeState = SpikeState.NotSpiking
				athlete.ReEvaluateState()
			pass

	pass
func Exit(_athlete:Athlete):
	pass

#func TimeToSpikeWithFullRunup() -> float:
#	var timeToGetToRunup = athlete.distance_to(athlete.spikeState.runupStartPosition)/athlete.stats.speed 
#	var timeToRunup = runupStartPosition.distance_to(takeOffXZ)/athlete.stats.speed
#	var timeToReach
