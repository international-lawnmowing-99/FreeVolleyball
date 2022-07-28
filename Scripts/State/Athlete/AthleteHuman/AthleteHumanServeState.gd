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

enum ServeType{
	UNDEFINED,
	Jump,
	Float,
	Underarm
}

enum ServeAggression{
	UNDEFINED,
	Controlled,
	Moderate,
	Aggressive
	}

var serveState = ServeState.NotServing
var serveAggression = ServeAggression.UNDEFINED
var serveType = ServeType.UNDEFINED
var serveTarget
var serveUI
var attackTarget
var takeOffTarget
var ball:Ball
	
func Enter(athlete:Athlete):
	nameOfState="HumanServe"
	
	ball = athlete.ball
	serveState = ServeState.Walking
	serveTarget = athlete.get_tree().root.get_node("MatchScene").get_node("ServeTarget")
	serveUI = athlete.get_tree().root.get_node("MatchScene").get_node("ServeUI")
	
	serveUI.humanServeState = self
	serveUI.ShowServeChoice()
	
	
	serveTarget.visible = false
	
func Update(athlete:Athlete):
	
	match serveState:
		ServeState.Walking:
			if Input.is_key_pressed(KEY_I):
				athlete.moveTarget.x -= .1
			if Input.is_key_pressed(KEY_J):
				athlete.moveTarget.z += .1
			if Input.is_key_pressed(KEY_L):
				athlete.moveTarget.z -= .1
			if Input.is_key_pressed(KEY_K):
				athlete.moveTarget.x += .1
			
			if Input.is_key_pressed(KEY_SPACE):
				athlete.moveTarget = athlete.translation
				serveState = ServeState.Aiming
				print("key pressed walking")
				serveTarget.visible = true
				serveUI.HideServeChoice()
			pass
		ServeState.Aiming:
			if Input.is_key_pressed(KEY_I):
				serveTarget.translation.x -= .1
			if Input.is_key_pressed(KEY_J):
				serveTarget.translation.z += .1
			if Input.is_key_pressed(KEY_L):
				serveTarget.translation.z -= .1
			if Input.is_key_pressed(KEY_K):
				serveTarget.translation.x += .1
				
			if Input.is_action_just_pressed("ui_accept"):
				print("key pressed aiming")
				attackTarget = Vector3(serveTarget.translation.x, 0, serveTarget.translation.z)
				Console.AddNewLine(athlete.stats.lastName + ": " + "serving")
				serveState = ServeState.Tossing
				serveTarget.visible = false
				
		ServeState.Tossing:
				var runupLength = 2.75
				var runup = Vector2(attackTarget.x - athlete.translation.x, attackTarget.z - athlete.translation.z).normalized() * runupLength

				var jumpDistance = runup.normalized() * athlete.stats.verticalJump / 2


				#ball.Unparent()

				var tossTarget = Vector3(athlete.translation.x + runup.x + jumpDistance.x, athlete.stats.spikeHeight, athlete.translation.z + runup.y + jumpDistance.y)
				takeOffTarget = Vector3(athlete.translation.x + runup.x, 0, athlete.translation.z + runup.y)

				ball.mode = RigidBody.MODE_RIGID
				ball.translation = Vector3(athlete.translation.x, ball.translation.y, athlete.translation.z)
				ball.linear_velocity = ball.FindWellBehavedParabola(ball.translation, tossTarget, athlete.stats.spikeHeight + 5)
				
				ball.rotation = Vector3.ZERO
				ball.angular_velocity = Vector3 ( rand_range(-.5,.5),rand_range(-.5,.5), rand_range(10,30))
				
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
				athlete.rb.mode = RigidBody.MODE_RIGID
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
					var topspin
					# did they stuff up the serve?? 
					# skill ~ 30 - 70 ~.5
					# expecting 5 - 30% error rate, depending on aggro, avg 10%
					
					
					var fuckupProb = .1#float(serveAggression + 1)/3 * float(1 - (athlete.stats.serve/100))
					var roll = randf()
					Console.AddNewLine("fuckup prob: " + str(fuckupProb) + "|| roll: " + str(roll))
					if roll < fuckupProb:
						#attackTarget = Vector3(rand_range(-10, 10), 0, rand_range(1, -8))
						topspin = 0
						ball.linear_velocity = ball.FindParabolaForGivenSpeed(ball.translation, attackTarget, 10 + 20 * randf(), false)
						ball.inPlay = true
						Console.AddNewLine("BAD SERVE. Serve Stat: " + str(athlete.stats.serve) + " Serve speed: " + str("%.1f" % (ball.linear_velocity.length() * 3.6)) + "km/h")
					else:
						topspin = rand_range(.5,1.8)
						ball.Serve(ball.translation, attackTarget, topspin)
						Console.AddNewLine("Serve Stat: " + str(athlete.stats.serve) + " Serve speed: " + str("%.1f" % (ball.linear_velocity.length() * 3.6)) + "km/h")
						athlete.get_tree().get_root().get_node("MatchScene").BallOverNet(true)
					
					ball.TouchedByA()
					serveState = ServeState.Landing



		ServeState.Landing:
			if (athlete.translation.y <= 0.01 && athlete.rb.linear_velocity.y < 0):
				athlete.rb.mode = RigidBody.MODE_KINEMATIC
				athlete.rb.gravity_scale = 0
				
				athlete.translation.y = 0
				serveState = ServeState.Walking
				athlete.stateMachine.SetCurrentState(athlete.defendState)


func Exit(athlete:Athlete):
	pass
