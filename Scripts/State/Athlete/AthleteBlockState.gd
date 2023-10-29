extends "res://Scripts/State/AthleteState.gd"
class_name AthleteBlockState

const SpikeState = preload("res://Scripts/State/Athlete/AthleteSpikeState.gd")
const Enums = preload("res://Scripts/World/Enums.gd")

enum BlockState{
UNDEFINED,
NotBlocking,
Watching,
Preparing,
Jump
}

var excludedFromBlock: bool = false

var commitBlockTarget:Athlete = null
var anticipateTarget:Athlete = null

var startingWidth:float

var isCommitBlocking:bool = false

var blockState = BlockState.NotBlocking

var blockingTarget:Athlete
var jumpTime:float

func Enter(athlete:Athlete):
	athlete.debug1.visible = true
	athlete.debug2.visible = true
	nameOfState="Block"
	athlete.animTree.set("parameters/state/transition_request", "moving")
	var jumpYVel = sqrt(2 * athlete.g * athlete.stats.verticalJump)
	jumpTime =  jumpYVel / athlete.g
	blockState = BlockState.Watching
	
	if athlete.role == Enums.Role.Middle:
		athlete.moveTarget = athlete.team.CheckIfFlipped(Vector3(0.5, 0, -0.5))
	if athlete == athlete.team.defendState.leftSideBlocker:
		athlete.moveTarget = athlete.team.CheckIfFlipped(Vector3(0.5, 0, 3)) 
	if athlete == athlete.team.defendState.rightSideBlocker:
		athlete.moveTarget = athlete.team.CheckIfFlipped(Vector3(0.5, 0, -3)) 
	
	athlete.blockState.startingWidth = athlete.moveTarget.z
	# won't show up until after ball served currently as they start in chill state
	
	athlete.leftIK.start()
	athlete.rightIK.start()
	athlete.leftIK.interpolation = 1.0
	athlete.rightIK.interpolation = 1.0
#	athlete.leftIKTarget.position = athlete.position# + athlete.model.transform.basis.x/4.0# + Vector3.UP * 2 + athlete.model.transform.basis.z
#	athlete.rightIKTarget.position = athlete.position# - athlete.model.transform.basis.x/4.0# + Vector3.UP * 2 + athlete.model.transform.basis.z
	
func Update(athlete:Athlete):
	athlete.DontFallThroughFloor()
	
	
	if blockingTarget:
		athlete.leftIKTarget.global_transform.origin = athlete.model.position + athlete.model.transform.basis.x/4.0 + Vector3.UP * 2 + athlete.model.transform.basis.z
		athlete.rightIKTarget.global_transform.origin = athlete.model.position + - athlete.model.transform.basis.x/4.0 + Vector3.UP * 2 + athlete.model.transform.basis.z

#		if athlete.team.isHuman && athlete == athlete.team.middleFront:
#			Console.AddNewLine(blockingTarget.stats.lastName + " blocking target")
		
#		athlete.leftIK.interpolation = lerp(athlete.leftIK.interpolation, 1.0, athlete.myDelta)
#		athlete.rightIK.interpolation = lerp(athlete.rightIK.interpolation, 1.0, athlete.myDelta)

		match blockState:
			BlockState.Watching:
				athlete.model.look_at(Maths.XZVector(athlete.ball.position) + Vector3(0, athlete.position.y, 0), Vector3.UP, true)
				
				if isCommitBlocking:
					if blockingTarget && (blockingTarget.spikeState.spikeState == SpikeState.SpikeState.Runup || blockingTarget.spikeState.spikeState == SpikeState.SpikeState.Jump):
						blockState = BlockState.Preparing
					
			BlockState.Preparing:
#					athlete.model.rotation.slerp(Vector3(0, -athlete.team.flip * PI/2, 0), athlete.myDelta * 10)
				athlete.model.rotation.y = -athlete.team.flip * PI/2
				#Perhaps adding a random offset would make this look less choreographed...
				var timeFromSpikeToNet = blockingTarget.setRequest.target.x/25
				if athlete.rb.freeze && blockingTarget.spikeState.CalculateTimeTillSpike(blockingTarget) + timeFromSpikeToNet <= jumpTime:
					Console.AddNewLine(athlete.stats.lastName + " jumps to block (commit)")
					blockState = BlockState.Jump	
					
					athlete.rb.freeze = false
					athlete.rb.gravity_scale = 1
					athlete.rb.linear_velocity = Maths.FindWellBehavedParabola(athlete.position, athlete.position, athlete.stats.verticalJump)

			BlockState.Jump:
				if blockingTarget.setRequest.target:
					athlete.leftIKTarget.global_transform.origin = blockingTarget.setRequest.target
					athlete.rightIKTarget.global_transform.origin = blockingTarget.setRequest.target
				
				if athlete.position.y < 0.1 && athlete.rb.linear_velocity.y < 0:
					blockState = BlockState.Watching
					athlete.rb.freeze = true
					athlete.position.y = 0
					athlete.rb.gravity_scale = 0
					if isCommitBlocking && athlete.team.stateMachine.currentState == athlete.team.defendState && blockingTarget.setRequest:
						if athlete == athlete.team.defendState.leftSideBlocker:
							pass
								
						elif athlete == athlete.team.defendState.middleBlocker:
							blockingTarget = athlete.team.defendState.otherTeam.chosenSpiker
							if athlete.team.flip * blockingTarget.setRequest.target.z >= 0:
								athlete.moveTarget = athlete.team.defendState.leftSideBlocker.moveTarget - athlete.team.flip * Vector3(0.5, 0, .75)
							else:
								athlete.moveTarget = athlete.team.defendState.rightSideBlocker.moveTarget + athlete.team.flip * Vector3(0.5, 0, .75)

						elif athlete == athlete.team.defendState.rightSideBlocker:
							pass
							
						else:
							Console.AddNewLine("ERROR, blocker not found for reassignment after commit block", Color.CRIMSON)
					else:
						athlete.ReEvaluateState()
#

#func OnBallSet(athlete:Athlete, newBlockingTarget:Athlete):
#	if !isCommitBlocking:
#		blockingTarget = newBlockingTarget
#
#		# moveTarget is now the set target +- an offset for where the pin blocker is
#		athlete.moveTarget = athlete.team.CheckIfFlipped(Vector3(0.5, 0, blockingTarget.setRequest.target.z))
#		pass

		athlete.debug1.global_transform.origin = athlete.leftIKTarget.global_transform.origin
		athlete.debug2.global_transform.origin = athlete.rightIKTarget.global_transform.origin
		
func Exit(athlete:Athlete):
	athlete.leftIK.stop()
	athlete.rightIK.stop()
	athlete.debug1.visible = false
	athlete.debug2.visible = false
	pass

func ConfirmCommitBlock(athlete:Athlete, otherTeam:Team):
	#	Console.AddNewLine(athlete.stats.lastName + " reconsidering whether to commit block, along with several other life choices")
	# If I'm commit blocking and the ball is passed, check the following to
	# see if I can ignore my commit target:
	# Is the ball too far from the net?
	# Is the pass too wide/low for the spiker to have enough time to run a quick?
	# Is the spiker likely to run a more shoot-y quick than expected to make up for their inability to run closer to the setter?
	# Balance personal embarassment at leaving the net undefended against maximising
	# defensive expected value of reacting to the other options that are now more likely
	
	if otherTeam.receptionTarget.x * otherTeam.flip > athlete.team.teamStrategy.maxCommitDistanceFromNet:
		isCommitBlocking = false
		Console.AddNewLine("The set will take place too far from the net for our tastes")
		return
	
	var timeForTargetToReachJumpPeak:float = blockingTarget.spikeState.CalculateTimeTillSpike(blockingTarget)
	var timeToSetBlockingTarget:float = otherTeam.timeTillDigTarget
	# Move to a more amenable position if applicable
	
