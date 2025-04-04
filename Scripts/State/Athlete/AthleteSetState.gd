extends "res://Scripts/State/AthleteState.gd"

class_name AthleteSetState

enum InternalSetState{
	Undefined,
	JumpSet,
	StandingSet
	}
enum JumpSetState{
	Undefined,
	PreSet,
	Jump
	}

var internalSetState = InternalSetState.Undefined
var jumpSetState = JumpSetState.Undefined

#var hasSet:bool = false
var interpolationSpeed = 10
func Enter(athlete:Athlete):
	athlete.animTree.set("parameters/state/transition_request", "moving")
	nameOfState="Set"

	athlete.moveTarget.y = 0
	athlete.leftIK.start()
	athlete.rightIK.start()
	athlete.leftIK.interpolation = 0
	athlete.rightIK.interpolation = 0
	athlete.leftIK.interpolation = 1#lerp(athlete.leftIK.interpolation, (1.1 - timeTillSet), 1)
	athlete.rightIK.interpolation = 1#lerp(athlete.rightIK.interpolation, (1.1 - timeTillSet), 1)

	if athlete.team.setter != athlete:
		print("who am I? " + athlete.stats.lastName)

	pass
func Update(athlete:Athlete):
	athlete.DontFallThroughFloor()
#	var ballDistance = athlete.position.distance_to(athlete.ball.position)
#	var ballXZVel = Vector2(athlete.ball.linear_velocity.x, athlete.ball.linear_velocity.z).length()
	var timeTillSet

	match internalSetState:
		InternalSetState.Undefined:
			timeTillSet = 99999
		InternalSetState.StandingSet:
			timeTillSet = Maths.TimeTillBallReachesHeight(athlete.ball.position, athlete.ball.linear_velocity, athlete.stats.standingSetHeight, 1.0)
		InternalSetState.JumpSet:
			timeTillSet = Maths.TimeTillBallReachesHeight(athlete.ball.position, athlete.ball.linear_velocity, athlete.stats.jumpSetHeight, 1.0)
			if jumpSetState != JumpSetState.Jump && athlete.position.distance_to(athlete.moveTarget) <= athlete.MoveDistanceDelta:
				var g = ProjectSettings.get_setting("physics/3d/default_gravity")
				var jumpYVel = sqrt(2 * g * athlete.stats.verticalJump)
				var jumpTime = jumpYVel / g

				if jumpTime >= timeTillSet:
					jumpSetState = JumpSetState.Jump
					if athlete.rb.freeze:
						athlete.rb.freeze = false
						athlete.rb.gravity_scale = 1
						athlete.rb.linear_velocity = Maths.FindWellBehavedParabola(athlete.position, athlete.position, athlete.stats.verticalJump)

			elif jumpSetState == JumpSetState.Jump:
				if athlete.position.y < 0.1 && athlete.rb.linear_velocity.y < 0:
					jumpSetState = JumpSetState.Undefined
					internalSetState = InternalSetState.Undefined
					athlete.rb.freeze = true
					athlete.position.y = 0
					athlete.rb.gravity_scale = 0
					athlete.ReEvaluateState()

	if athlete.ball:
		athlete.leftIKTarget.global_transform.origin = athlete.ball.global_transform.origin + athlete.model.transform.basis.x/8.0
#		athlete.leftIKTarget.position.slerp (athlete.ball.position, athlete.myDelta * interpolationSpeed)
		athlete.rightIKTarget.global_transform.origin = athlete.ball.global_transform.origin - athlete.model.transform.basis.x/8.0

#		Console.AddNewLine("time till set " + str("%0.2f" % timeTillSet))
#		athlete.team.mManager.cube.position = athlete.position + athlete.get_node("new new woman import").transform.basis.x
#	if athlete.team.flip > 0:
#		athlete.rotation.y = lerp_angle(athlete.rotation.y, 0, athlete.myDelta * 5)
#	else:
#		athlete.rotation.y = lerp_angle(athlete.rotation.y, PI, athlete.myDelta * 5)


func Exit(athlete:Athlete):
	athlete.leftIK.stop()
	athlete.rightIK.stop()
	pass

func WaitThenDefend(athlete:Athlete, time:float):
	athlete.stateMachine.isStateLocked = true

	athlete.stateMachine.SetCurrentState(athlete.defendState)
	await athlete.get_tree().create_timer(time).timeout
	if athlete.stateMachine.isStateLocked:
		athlete.stateMachine.isStateLocked = false
		if athlete.stateMachine.queuedState:
			athlete.stateMachine.SetCurrentState(athlete.stateMachine.queuedState)
		else:
			athlete.stateMachine.SetCurrentState(athlete.defendState)


func TimeToJumpSet(athlete:Athlete, receptionTarget:Vector3):
	var g = ProjectSettings.get_setting("physics/3d/default_gravity")

	var timeToReachGround = 0
	if !athlete.rb.freeze:
		if athlete.rb.linear_velocity.y > 0:
			#they're going up
			timeToReachGround = athlete.linear_velocity.y/-g + sqrt(2 * g * athlete.stats.verticalJump)/athlete.g
		else:
			#they're falling
			timeToReachGround = sqrt(2 * g * athlete.position.y)

	var distanceToRecetionTarget = Vector3(athlete.position.x, 0, athlete.position.z).distance_to(Vector3(receptionTarget.x, 0, receptionTarget.z))
	var timeToMoveIntoPosition =  distanceToRecetionTarget / athlete.stats.speed

	var jumpYVel = sqrt(2 * g * athlete.stats.verticalJump)
	var jumpTime = jumpYVel / g

	#print("Time to execute jump set: " + str(timeToMoveIntoPosition + jumpTime))

	return timeToReachGround + timeToMoveIntoPosition + jumpTime

func TimeToStandingSet(athlete:Athlete, receptionTarget:Vector3):
	var timeToReachGround = 0
	if !athlete.rb.freeze:
		if athlete.rb.linear_velocity.y > 0:
			#they're going up
			timeToReachGround = athlete.linear_velocity.y/-athlete.g + sqrt(2 * athlete.g * athlete.stats.verticalJump)/athlete.g
		else:
			#they're falling
			timeToReachGround = sqrt(2 * athlete.g * athlete.position.y)
	var distanceToRecetionTarget = Vector3(athlete.position.x, 0, athlete.position.z).distance_to(Vector3(receptionTarget.x, 0, receptionTarget.z))
	return timeToReachGround + distanceToRecetionTarget / athlete.stats.speed
