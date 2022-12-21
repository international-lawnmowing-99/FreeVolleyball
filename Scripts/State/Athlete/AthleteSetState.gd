extends "res://Scripts/State/AthleteState.gd"
enum SetState{ 
	Undefined,
	JumpSet,
	StandingSet
	}
enum JumpSetState{
	Undefined,
	PreSet,
	Jump
	}
	
var setState = SetState.Undefined
var jumpSetState = JumpSetState.Undefined

#var hasSet:bool = false
var interpolationSpeed = 5
func Enter(athlete:Athlete):
	nameOfState="Set"

	athlete.moveTarget.y = 0
	athlete.leftIK.start()
	athlete.rightIK.start()
	athlete.leftIK.interpolation = 0
	athlete.rightIK.interpolation = 0
	
	pass
func Update(athlete:Athlete):
#	var ballDistance = athlete.translation.distance_to(athlete.ball.translation)
#	var ballXZVel = Vector2(athlete.ball.linear_velocity.x, athlete.ball.linear_velocity.z).length()
	var timeTillSet 
	
	match setState:
		SetState.Undefined:
			timeTillSet = 99999
		SetState.StandingSet:
			timeTillSet = athlete.ball.TimeTillBallReachesHeight(athlete.stats.standingSetHeight)
		SetState.JumpSet:
			timeTillSet = athlete.ball.TimeTillBallReachesHeight(athlete.stats.jumpSetHeight)
			if jumpSetState != JumpSetState.Jump && athlete.translation.distance_to(athlete.moveTarget) <= athlete.MoveDistanceDelta:
				var g = ProjectSettings.get_setting("physics/3d/default_gravity")
				var jumpYVel = sqrt(2 * g * athlete.stats.verticalJump)
				var jumpTime = jumpYVel / g
				
				if jumpTime >= timeTillSet:
					jumpSetState = JumpSetState.Jump
					if athlete.rb.mode !=  RigidBody.MODE_RIGID:
						athlete.rb.mode = RigidBody.MODE_RIGID
						athlete.rb.gravity_scale = 1
						athlete.rb.linear_velocity = athlete.ball.FindWellBehavedParabola(athlete.translation, athlete.translation, athlete.stats.verticalJump)
			
			elif jumpSetState == JumpSetState.Jump:
				if athlete.translation.y < 0.1 && athlete.rb.linear_velocity.y < 0:
					jumpSetState = JumpSetState.Undefined
					setState = SetState.Undefined
					athlete.rb.mode = RigidBody.MODE_KINEMATIC
					athlete.translation.y = 0
					athlete.rb.gravity_scale = 0
					athlete.ReEvaluateState()
	
		
	athlete.leftIKTarget.global_transform.origin = lerp (athlete.leftIKTarget.global_transform.origin, athlete.ball.translation, athlete.myDelta * interpolationSpeed)
	athlete.rightIKTarget.global_transform.origin = lerp (athlete.rightIKTarget.global_transform.origin, athlete.ball.translation, athlete.myDelta * interpolationSpeed)
	athlete.leftIK.interpolation = lerp(athlete.leftIK.interpolation, (1 - timeTillSet), athlete.myDelta * interpolationSpeed)
	athlete.rightIK.interpolation = lerp(athlete.rightIK.interpolation, (1 - timeTillSet), athlete.myDelta * interpolationSpeed)
	if athlete.team.flip > 0:
		athlete.rotation.y = lerp_angle(athlete.rotation.y, 0, athlete.myDelta * 5)
	else:
		athlete.rotation.y = lerp_angle(athlete.rotation.y, PI, athlete.myDelta * 5)
	
	
func Exit(athlete:Athlete):
	athlete.leftIK.stop()
	athlete.rightIK.stop()
	pass

func WaitThenDefend(athlete:Athlete, time:float):
	yield(athlete.get_tree().create_timer(time), "timeout")
	
	athlete.stateMachine.SetCurrentState(athlete.defendState)

func TimeToJumpSet(athlete:Athlete, receptionTarget:Vector3):
	var g = ProjectSettings.get_setting("physics/3d/default_gravity")
	
	var distanceToRecetionTarget = athlete.translation.distance_to(Vector3(receptionTarget.x, 0, receptionTarget.z))
	var timeToMoveIntoPosition =  distanceToRecetionTarget / athlete.stats.speed
	
	var jumpYVel = sqrt(2 * g * athlete.stats.verticalJump)
	var jumpTime = jumpYVel / g
	
	#print("Time to execute jump set: " + str(timeToMoveIntoPosition + jumpTime))
	
	return timeToMoveIntoPosition + jumpTime

func TimeToStandingSet(athlete:Athlete, receptionTarget:Vector3):
	var distanceToRecetionTarget = athlete.translation.distance_to(Vector3(receptionTarget.x, 0, receptionTarget.z))
	return  distanceToRecetionTarget / athlete.stats.speed
	
