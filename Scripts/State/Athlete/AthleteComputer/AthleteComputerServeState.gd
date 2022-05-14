extends "res://Scripts/State/AthleteState.gd"

enum ServeState{
NotServing,
Walking,
Aiming,
Tossing,
WatchingTheBallInTheAir,
Runup,
Jump,
Landing
}

var serveState
var ball:Ball
var takeOffTarget
var attackTarget

func Enter(athlete:Athlete):
	nameOfState="ComputerServe"
	ball = athlete.ball
	serveState = ServeState.Walking
	athlete.moveTarget = Vector3(-11.5, 0, 2)
	athlete.rb.mode = RigidBody.MODE_KINEMATIC
	pass
	
func Update(athlete:Athlete):
	match serveState:
		ServeState.Walking:
			if athlete.translation.distance_to(athlete.moveTarget) < 0.1:
				athlete.look_at_from_position(athlete.translation, Vector3.ZERO, Vector3.UP)
				serveState = ServeState.Aiming
			
		ServeState.Aiming:
			
			attackTarget = Vector3(rand_range(3, 10), 0, rand_range(-5, 5))
			athlete.get_tree().root.find_node("MatchScene", true, false).console.AddNewLine(athlete.stats.lastName + " jump serve, max aggression: GOOD SERVE")
			
			#anim.SetTrigger("jumpServeToss");
			serveState = ServeState.Tossing
		
		ServeState.Tossing:
#we want to hit it after a 3m runup and a jump
			if (true):
				var runupLength = 2.75
				var runup = Vector2(attackTarget.x - athlete.translation.x, attackTarget.z - athlete.translation.z).normalized() * runupLength

				var jumpDistance = runup.normalized() * athlete.stats.verticalJump / 2


				#ball.Unparent()

				var tossTarget = Vector3(athlete.translation.x + runup.x + jumpDistance.x, athlete.stats.spikeHeight, athlete.translation.z + runup.y + jumpDistance.y)
				takeOffTarget = Vector3(athlete.translation.x + runup.x, 0, athlete.translation.z + runup.y)

				ball.mode = RigidBody.MODE_RIGID
				ball.linear_velocity = ball.FindWellBehavedParabola(ball.translation, tossTarget, athlete.stats.spikeHeight + 5)
				
				ball.rotation = Vector3.ZERO
				ball.angular_velocity = Vector3 ( rand_range(-.5,.5),rand_range(-.5,.5), rand_range(-10,-30))
				
				serveState = ServeState.WatchingTheBallInTheAir
				#anim.SetTrigger("startRunup");



		ServeState.WatchingTheBallInTheAir:
			#transform.rotation = Quaternion.RotateTowards(transform.rotation, Quaternion.LookRotation(MyMaths.xzVector(ball.attackTarget - transform.position)), 15 * Time.deltaTime);
			if (ball.TimeTillBallReachesHeight(athlete.stats.spikeHeight) <= athlete.CalculateTimeTillJumpPeak(takeOffTarget)):
				serveState = ServeState.Runup
				athlete.moveTarget = takeOffTarget
		
		ServeState.Runup:
			var distanceToTakeoff = athlete.translation.distance_to(takeOffTarget)
			if (distanceToTakeoff >= .1):
				#transform.rotation = Quaternion.RotateTowards(transform.rotation, Quaternion.LookRotation(MyMaths.xzVector(ball.attackTarget - transform.position)), 45 * Time.deltaTime);
				pass#athlete.BaseMove()

			else:
				athlete.rb.mode =RigidBody.MODE_RIGID
				athlete.rb.gravity_scale = 1

				var landing = athlete.translation + Vector3(attackTarget.x - athlete.translation.x, 0, attackTarget.z - athlete.translation.z).normalized() * athlete.stats.verticalJump
				
				#Again, don't ask me why this is needed
				athlete.rb.linear_velocity = ball.FindWellBehavedParabola(athlete.translation, landing, athlete.stats.verticalJump)
				yield(athlete.get_tree(),"idle_frame")
				athlete.rb.linear_velocity = ball.FindWellBehavedParabola(athlete.translation, landing, athlete.stats.verticalJump)
				
				
				serveState = ServeState.Jump
				#if (timeTillJumpPeak<= jumpAnimationTime)
				#anim.SetTrigger("jump");

		ServeState.Jump:
			#if athlete.rb.linear_velocity.y >0:
				if ball.linear_velocity.y < 0 && athlete.stats.spikeHeight >= ball.translation.y:
					var topspin = rand_range(.5,1.8)
					ball.Serve(ball.translation, attackTarget, topspin)
					ball.TouchedByB()
					serveState = ServeState.Landing

					athlete.get_tree().get_root().get_node("MatchScene").BallOverNet(false)
					athlete.get_tree().root.find_node("MatchScene", true, false).console.AddNewLine("Serve speed: " + str("%.1f" % (ball.linear_velocity.length() * 3.6)) + "km/h")
		ServeState.Landing:
			if (athlete.translation.y <= 0.01 && athlete.rb.linear_velocity.y < 0):
				athlete.rb.mode =RigidBody.MODE_KINEMATIC
				athlete.rb.gravity_scale = 0
				
				athlete.translation.y = 0
				serveState = ServeState.Walking
				athlete.stateMachine.SetCurrentState(athlete.defendState)

	
func Exit(athlete:Athlete):
	pass
