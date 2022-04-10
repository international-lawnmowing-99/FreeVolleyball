extends "res://Scripts/State/AthleteState.gd"
const SpikeState = preload("res://Scripts/State/Athlete/AthleteSpikeState.gd")
const Enums = preload("res://Scripts/World/Enums.gd")

enum BlockState{
UNDEFINED,
NotBlocking,
Watching,
Preparing,
Jump
}

var blockState = BlockState.NotBlocking

var blockingTarget:Athlete
var timeTillBlockPeak:float

func Enter(athlete:Athlete):
	nameOfState="Block"
	var jumpYVel = sqrt(2 * athlete.g * athlete.stats.verticalJump)
	timeTillBlockPeak =  jumpYVel / athlete.g
	blockState = BlockState.Watching
	pass
func Update(athlete:Athlete):
	match blockState:
		BlockState.Watching:
			if blockingTarget.spikeState.spikeState == SpikeState.SpikeState.Runup:
				blockState = BlockState.Preparing
			if athlete.role == Enums.Role.Middle:
				#well this is silly... 
				if athlete.team.isHuman:
					athlete.moveTarget = athlete.team.CheckIfFlipped(Vector3(-.5, 0, blockingTarget.spikeState.takeOffXZ.z))
				else:
					athlete.moveTarget = athlete.team.CheckIfFlipped(Vector3(.5, 0, blockingTarget.spikeState.takeOffXZ.z))
		BlockState.Preparing:
			#Perhaps adding a random offset would make this look less choreographed...
			if blockingTarget.CalculateTimeTillJumpPeak(blockingTarget.spikeState.takeOffXZ) <=timeTillBlockPeak:
				blockState = BlockState.Jump	
				if athlete.rb.mode !=  RigidBody.MODE_RIGID:
					athlete.rb.mode = RigidBody.MODE_RIGID
					athlete.rb.gravity_scale = 1
					#Again, don't ask me why this is needed
					athlete.rb.linear_velocity = athlete.ball.FindWellBehavedParabola(athlete.translation, athlete.translation, athlete.stats.verticalJump)
					yield(athlete.get_tree(),"idle_frame")
					athlete.rb.linear_velocity = athlete.ball.FindWellBehavedParabola(athlete.translation, athlete.translation, athlete.stats.verticalJump)
		BlockState.Jump:
			if athlete.translation.y < 0.1 && athlete.rb.linear_velocity.y < 0:
				blockState = BlockState.Watching
				athlete.rb.mode = RigidBody.MODE_KINEMATIC
				athlete.translation.y = 0
				athlete.rb.gravity_scale = 0
				athlete.ReEvaluateState()
#				if athlete.team.isNextToAttack:
#					athlete.stateMachine.SetCurrentState(athlete.spikeState)

func Exit(athlete:Athlete):
	pass
