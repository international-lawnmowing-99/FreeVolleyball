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
var timeTillJumpPeak
var spikeState = SpikeState.NotSpiking
#var athlete:Athlete
var spikeValue:float = 0
var runupStartPosition:Vector3

func Enter(athlete:Athlete):
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
			CalculateTakeOffXZ(athlete)
	
			var timeTillBallReachesSetTarget:float 
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
				
			timeTillBallReachesSetTarget = athlete.team.timeTillDigTarget + setTime
			
			if timeTillBallReachesSetTarget <= athlete.CalculateTimeTillJumpPeak(takeOffXZ) && athlete.team.stateMachine.currentState != athlete.team.receiveState:
				spikeState = SpikeState.Runup
				athlete.moveTarget = takeOffXZ
#				print(athlete.stats.lastName + " " + str(athlete.CalculateTimeTillJumpPeak(takeOffXZ)))
#				print(str(timeTillBallReachesSetTarget) + str(athlete.team.stateMachine.currentState))

		SpikeState.Runup:
			if Maths.XZVector(takeOffXZ - athlete.position).length() < 0.1:
				spikeState = SpikeState.Jump
				athlete.rightIK.start()
				athlete.rightIK.interpolation = 1
				if athlete.rb.freeze:
					athlete.rb.freeze = false
					athlete.rb.gravity_scale = 1
					# We want to contact the ball at our max height...
					# This means a steeper jump for more extreme verticals
					athlete.rb.linear_velocity = athlete.team.ball.FindWellBehavedParabola(athlete.position, Vector3(athlete.setRequest.target.x, 0, athlete.setRequest.target.z), athlete.stats.verticalJump)

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
	var landingPos = Vector3(athlete.setRequest.x, 0, athlete.setRequest.z)
	takeOffXZ = Maths.XZVector(athlete.setRequest.target + (athlete.position - athlete.setRequest.target) * (athlete.stats.verticalJump/2 / (Maths.XZVector(athlete.position - athlete.setRequest.target).length())))
	
func Exit(_athlete:Athlete):
	pass

func ReactToDodgySet():
	pass

#func TimeToSpikeWithFullRunup() -> float:
#	var timeToGetToRunup = athlete.distance_to(athlete.spikeState.runupStartPosition)/athlete.stats.speed 
#	var timeToRunup = runupStartPosition.distance_to(takeOffXZ)/athlete.stats.speed
#	var timeToReach
