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
var timeTillBlockPeak:float

func Enter(athlete:Athlete):
	nameOfState="Block"
	athlete.animTree.set("parameters/state/transition_request", "moving")
	var jumpYVel = sqrt(2 * athlete.g * athlete.stats.verticalJump)
	timeTillBlockPeak =  jumpYVel / athlete.g
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
	
	
func Update(athlete:Athlete):
	athlete.DontFallThroughFloor()
	
	if blockingTarget:
		if isCommitBlocking:
			match blockState:
				BlockState.Watching:
					if blockingTarget && (blockingTarget.spikeState.spikeState == SpikeState.SpikeState.Runup || blockingTarget.spikeState.spikeState == SpikeState.SpikeState.Jump):
						blockState = BlockState.Preparing
#						if athlete.role == Enums.Role.Middle && blockingTarget == athlete.team.defendState.otherTeam.middleFront:
#							if athlete.team.isHuman:
#								athlete.moveTarget = Vector3(.5, 0, blockingTarget.spikeState.takeOffXZ.z)
#							else:
#								athlete.moveTarget = Vector3(-.5, 0, blockingTarget.spikeState.takeOffXZ.z)
				BlockState.Preparing:
					#Perhaps adding a random offset would make this look less choreographed...
					if blockingTarget.CalculateTimeTillJumpPeak(blockingTarget.spikeState.takeOffXZ) <=timeTillBlockPeak:
						blockState = BlockState.Jump	
						if athlete.rb.freeze:
							athlete.rb.freeze = false
							athlete.rb.gravity_scale = 1
							athlete.rb.linear_velocity = athlete.ball.FindWellBehavedParabola(athlete.position, athlete.position, athlete.stats.verticalJump)
				BlockState.Jump:
					athlete.leftIKTarget.global_transform.origin = lerp(athlete.leftIKTarget.global_transform.origin, blockingTarget.setRequest.target, 20*athlete.myDelta)
					athlete.rightIKTarget.global_transform.origin = lerp(athlete.rightIKTarget.global_transform.origin, blockingTarget.setRequest.target, 20*athlete.myDelta)
					#if athlete.role == Enums.Role.Opposite:
						#(str(blockingTarget.setRequest.target))
						#print(str(athlete.rightIKTarget.position))
					
					if athlete.position.y < 0.1 && athlete.rb.linear_velocity.y < 0:
						blockState = BlockState.Watching
						athlete.rb.freeze = true
						athlete.position.y = 0
						athlete.rb.gravity_scale = 0
						athlete.ReEvaluateState()

		else:
			# React Blocking
			match blockState:
				BlockState.Watching:
					pass
				BlockState.Preparing:
					if blockingTarget.setRequest.target:
						athlete.leftIKTarget.global_transform.origin = lerp(athlete.leftIKTarget.global_transform.origin, blockingTarget.setRequest.target, 20*athlete.myDelta)
						athlete.rightIKTarget.global_transform.origin = lerp(athlete.rightIKTarget.global_transform.origin, blockingTarget.setRequest.target, 20*athlete.myDelta)
					#Perhaps adding a random offset would make this look less choreographed...
					if blockingTarget.CalculateTimeTillJumpPeak(blockingTarget.spikeState.takeOffXZ) <=timeTillBlockPeak:
						blockState = BlockState.Jump	
						if athlete.rb.freeze:
							athlete.rb.freeze = false
							athlete.rb.gravity_scale = 1
							athlete.rb.linear_velocity = athlete.ball.FindWellBehavedParabola(athlete.position, athlete.position, athlete.stats.verticalJump)
				BlockState.Jump:
					if blockingTarget.setRequest.target:
						athlete.leftIKTarget.global_transform.origin = lerp(athlete.leftIKTarget.global_transform.origin, blockingTarget.setRequest.target, 20*athlete.myDelta)
						athlete.rightIKTarget.global_transform.origin = lerp(athlete.rightIKTarget.global_transform.origin, blockingTarget.setRequest.target, 20*athlete.myDelta)
					#if athlete.role == Enums.Role.Opposite:
						#(str(blockingTarget.setRequest.target))
						#print(str(athlete.rightIKTarget.position))
					
					if athlete.position.y < 0.1 && athlete.rb.linear_velocity.y < 0:
						blockState = BlockState.Watching
						athlete.rb.freeze = true
						athlete.position.y = 0
						athlete.rb.gravity_scale = 0
						athlete.ReEvaluateState()
#

#func OnBallSet(athlete:Athlete, newBlockingTarget:Athlete):
#	if !isCommitBlocking:
#		blockingTarget = newBlockingTarget
#
#		# moveTarget is now the set target +- an offset for where the pin blocker is
#		athlete.moveTarget = athlete.team.CheckIfFlipped(Vector3(0.5, 0, blockingTarget.setRequest.target.z))
#		pass

func Exit(athlete:Athlete):
	athlete.leftIK.stop()
	athlete.rightIK.stop()
	pass

func ConfirmCommitBlock(athlete:Athlete, otherTeam:Team):
	Console.AddNewLine(athlete.stats.lastName + " reconsidering whether to commit block, along with several other life choices")
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
	
	var timeForTargetToReachJumpPeak:float = blockingTarget.CalculateTimeTillJumpPeak(blockingTarget.spikeState.takeOffXZ)
	var timeToSetBlockingTarget:float = otherTeam.timeTillDigTarget
	# Move to a more amenable position if applicable
	
