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
	Safety,
	Moderate,
	Aggressive
	}
const MAXTOPSPIN = 1.8
const MINTOPSPIN = 0.4

var serveState
var serveAggression = ServeAggression.UNDEFINED
var serveType = ServeType.UNDEFINED

var ball:Ball
var takeOffTarget
var attackTarget
var outputString:String


func Enter(athlete:Athlete):
	randomize()
	nameOfState="ComputerServe"
	ball = athlete.ball
	serveState = ServeState.Walking
	athlete.moveTarget = Vector3(-11.5, 0, 2)
	athlete.rb.mode = RigidBody.MODE_KINEMATIC
	
	outputString = ""
	
func Update(athlete:Athlete):
	match serveState:
		ServeState.Walking:
			if athlete.translation.distance_to(athlete.moveTarget) < 0.1:
				#athlete.look_at(Vector3.ZERO, -Vector3.UP)
				serveState = ServeState.Aiming
			
		ServeState.Aiming:
			#Decide what to do...
			var randServeType = randi()%3
			if randServeType == 0:
				serveType = ServeType.Underarm
				outputString += "Underarm serve, the lad!"
			elif randServeType == 1:
				serveType = ServeType.Float
				outputString += "Float serve"
			elif randServeType == 2:
				serveType = ServeType.Jump
				outputString += "Jump serve"

			#Choose aggression
			var randServeAggression = randi()%3
			
			if randServeAggression == 0:
				serveAggression = ServeAggression.Safety
				outputString += " - safety serve"
			elif randServeAggression == 1:
				serveAggression = ServeAggression.Moderate
				outputString += " - average aggression"
			elif randServeAggression == 2:
				serveAggression = ServeAggression.Aggressive
				outputString += " - going for glory"

			#Choose target

			attackTarget = Vector3(rand_range(3, 10), 0, rand_range(-5, 5))
			Console.AddNewLine(athlete.stats.lastName + ": " + outputString)
			
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
					var topspin = 0
					# did they stuff up the serve?? 
					# skill ~ 30 - 70 ~.5
					# expecting 5 - 30% error rate, depending on aggro, avg 10%
					
					
					var fuckupProb = .1#float(serveAggression + 1)/3 * float(1 - (athlete.stats.serve/100))

					match serveAggression:
						ServeAggression.Aggressive:
							fuckupProb *= 2
						ServeAggression.Safety:
							fuckupProb /= 2
					
					var roll = randf()
					#Console.AddNewLine("fuckup prob: " + str(fuckupProb) + "|| roll: " + str(roll))
					if roll < fuckupProb:
						attackTarget = Vector3(rand_range(-1, 8), 0, rand_range(-10, 10))
						topspin = 0
						ball.linear_velocity = ball.FindParabolaForGivenSpeed(ball.translation, attackTarget, 10 + 30 * randf(), false)
						ball.inPlay = false
						Console.AddNewLine("BAD SERVE. Serve Stat: " + str(athlete.stats.serve) + " Serve speed: " + str("%.1f" % (ball.linear_velocity.length() * 3.6)) + "km/h")
						ball.mManager.PointToTeamA()
					else:
						if serveType == ServeType.Float:
							ball.floating = true
						elif serveType == ServeType.Jump:
							topspin = rand_range(.5, 1.8)
						ball.Serve(ball.translation, attackTarget, topspin)
						Console.AddNewLine("Serve Stat: " + str(athlete.stats.serve) + " Serve speed: " + str("%.1f" % (ball.linear_velocity.length() * 3.6)) + "km/h")
						athlete.get_tree().get_root().get_node("MatchScene").BallOverNet(false)
						
						var difficultyOfReception = 0
						match serveAggression:
							ServeAggression.Aggressive:
								difficultyOfReception = rand_range(athlete.stats.serve * 2/3, athlete.stats.serve)
							ServeAggression.Moderate:
								difficultyOfReception = rand_range(athlete.stats.serve/3, athlete.stats.serve * 2/3)
							ServeAggression.Safety:
								difficultyOfReception = rand_range(0, athlete.stats.serve/3)
						
						ball.difficultyOfReception = difficultyOfReception
						
						
					
					ball.TouchedByB()
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
