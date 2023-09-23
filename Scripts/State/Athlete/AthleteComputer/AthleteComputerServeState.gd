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

var serveState:ServeState
var serveAggression:ServeAggression = ServeAggression.UNDEFINED
var serveType:ServeType = ServeType.UNDEFINED

var ball:Ball
var takeOffTarget:Vector3
var attackTarget:Vector3
var outputString:String

var runupLength:float
var runup:Vector2
var jumpDistance:Vector2

func Enter(athlete:Athlete):
	runupLength = athlete.stats.height * 2.75
	randomize()
	athlete.animTree.set("parameters/state/transition_request", "moving")
	nameOfState="ComputerServe"
	ball = athlete.ball
	serveState = ServeState.Walking

	athlete.rb.freeze = true
	
	outputString = ""
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

	attackTarget = Vector3(randf_range(3, 10), 0, randf_range(-5, 5))
	Console.AddNewLine(athlete.stats.lastName + ": " + outputString)
	takeOffTarget = Vector3(-9 - randf_range(0.1, .5), 0, randf_range(-4, 4))
	
	
	runup = Vector2(attackTarget.x - takeOffTarget.x, attackTarget.z - takeOffTarget.z).normalized() * runupLength

	jumpDistance = runup.normalized() * athlete.stats.verticalJump / 2
	
	athlete.moveTarget = Vector3(takeOffTarget.x - jumpDistance.x - runup.x, 0, takeOffTarget.z - jumpDistance.y - runup.y)
	
func Update(athlete:Athlete):
	match serveState:
		ServeState.Walking:
			ball.position = athlete.position + Vector3.UP
			if athlete.position.distance_to(athlete.moveTarget) < 0.1:
				#athlete.look_at(Vector3.ZERO, -Vector3.UP)
				athlete.model.rotation = Vector3(0, PI/2, 0)
				serveState = ServeState.Tossing
		
		ServeState.Tossing:
			#ball.Unparent()

			var tossTarget = Vector3(takeOffTarget.x + jumpDistance.x, athlete.stats.spikeHeight, takeOffTarget.z + jumpDistance.y)

			ball.freeze = false
			ball.linear_velocity = Maths.FindWellBehavedParabola(ball.position, tossTarget, athlete.stats.spikeHeight + randf_range(4,5.5))
			
			ball.rotation = Vector3.ZERO
			ball.angular_velocity = Vector3 ( randf_range(-.5,.5),randf_range(-.5,.5), randf_range(-10,-30))
			
			serveState = ServeState.WatchingTheBallInTheAir
			#anim.SetTrigger("startRunup");



		ServeState.WatchingTheBallInTheAir:
			#transform.rotation = Quaternion.RotateTowards(transform.rotation, Quaternion.LookRotation(MyMaths.xzVector(ball.attackTarget - transform.position)), 15 * Time.deltaTime);
			if (Maths.TimeTillBallReachesHeight(athlete.ball.position, athlete.ball.linear_velocity, athlete.stats.spikeHeight, 1.0) <= athlete.CalculateTimeTillJumpPeak(takeOffTarget)):
				serveState = ServeState.Runup
				athlete.moveTarget = takeOffTarget
		
		ServeState.Runup:
			var distanceToTakeoff = athlete.position.distance_to(takeOffTarget)
			if (distanceToTakeoff >= .1):
				#transform.rotation = Quaternion.RotateTowards(transform.rotation, Quaternion.LookRotation(MyMaths.xzVector(ball.attackTarget - transform.position)), 45 * Time.deltaTime);
				pass#athlete.BaseMove()

			else:
				athlete.rb.freeze = false
				athlete.rb.gravity_scale = 1

				var landing = athlete.position + Vector3(attackTarget.x - athlete.position.x, 0, attackTarget.z - athlete.position.z).normalized() * athlete.stats.verticalJump
				

				athlete.rb.linear_velocity = Maths.FindWellBehavedParabola(athlete.position, landing, athlete.stats.verticalJump)
				
				serveState = ServeState.Jump
				athlete.rightIK.start()
				athlete.rightIK.interpolation = 1
				#if (timeTillJumpPeak<= jumpAnimationTime)
				#anim.SetTrigger("jump");

		ServeState.Jump:
				athlete.rightIKTarget.position = athlete.ball.position
				athlete.rightIK.interpolation = 1
			#if athlete.rb.linear_velocity.y >0:
				if ball.linear_velocity.y < 0 && athlete.stats.spikeHeight >= ball.position.y:
					ball.topspin = 1.0
					# did they stuff up the serve?? 
					# skill ~ 30 - 70 ~.5
					# expecting 5 - 30% error rate, depending checked aggro, avg 10%
					
					
					var fuckupProb = .1#float(serveAggression + 1)/3 * float(1 - (athlete.stats.serve/100))

					match serveAggression:
						ServeAggression.Aggressive:
							fuckupProb *= 2
						ServeAggression.Safety:
							fuckupProb /= 2
					
					var roll = randf()
					#Console.AddNewLine("fuckup prob: " + str(fuckupProb) + "|| roll: " + str(roll))
					if roll < fuckupProb:
						attackTarget = Vector3(randf_range(-1, 8), 0, randf_range(-10, 10))
						ball.topspin = 1.0
						ball.linear_velocity = Maths.FindParabolaForGivenSpeed(ball.position, attackTarget, 10 + 20 * randf(), false, ball.topspin)
						ball.inPlay = false
						Console.AddNewLine("BAD SERVE. Serve Stat: " + str(athlete.stats.serve) + " Serve speed: " + str("%.1f" % (ball.linear_velocity.length() * 3.6)) + "km/h")
						ball.mManager.PointToTeamA()
					else:
						if serveType == ServeType.Float:
							ball.floating = true
						elif serveType == ServeType.Jump:
							ball.topspin = 1 + randf_range(.5, 1.8)
						ball.Serve(ball.position, attackTarget, 2.8, ball.topspin)
#						Console.AddNewLine("Serve Stat: " + str(athlete.stats.serve) + " Serve speed: " + str("%.1f" % (ball.linear_velocity.length() * 3.6)) + "km/h")
						athlete.team.mManager.BallOverNet(false)
						
						var difficultyOfReception = 0
						match serveAggression:
							ServeAggression.Aggressive:
								difficultyOfReception = randf_range(athlete.stats.serve * 2/3, athlete.stats.serve)
							ServeAggression.Moderate:
								difficultyOfReception = randf_range(athlete.stats.serve/3, athlete.stats.serve * 2/3)
							ServeAggression.Safety:
								difficultyOfReception = randf_range(0, athlete.stats.serve/3)
						
						ball.difficultyOfReception = difficultyOfReception
						
						
					
					ball.TouchedByB()
					serveState = ServeState.Landing



		ServeState.Landing:
			if (athlete.position.y <= 0.01 && athlete.rb.linear_velocity.y < 0):
				athlete.rb.freeze = true
				athlete.rb.gravity_scale = 0
				
				athlete.position.y = 0
				serveState = ServeState.Walking
				athlete.stateMachine.SetCurrentState(athlete.defendState)

	
func Exit(athlete:Athlete):
	athlete.rightIK.stop()
	athlete.rightIK.interpolation = 0
	pass
