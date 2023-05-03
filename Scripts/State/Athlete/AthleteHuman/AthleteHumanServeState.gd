extends "res://Scripts/State/AthleteState.gd"

class_name AthleteHumanServeState

enum ServeState{
NotServing,
Walking,
ChoosingServeType,
ChoosingServeAggression,
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

var _athlete
var serveState = ServeState.NotServing
var serveAggression = ServeAggression.UNDEFINED
var serveType = ServeType.UNDEFINED
var serveTarget:CSGMesh3D
var serveUI:ServeUI
var attackTarget
var takeOffTarget
var ball:Ball
var rememberSettings:bool = true
var rememberedServeTarget
var rememberedWalkPosition
var rememberedServeType
var rememberedServeAggression

# -x, x, -z, z
const AGGRESSIVEJUMPBOUNDS = [-10, -6.25, -5, 5]
const FLOATANDSOFTJUMPBOUNDS = [-10, -3, -5, 5]
const UNDERARMBOUNDS = [-10, -.5, -5, 5]

const WALKBOUNDS = [9.25, 15.5, -4.25, 4.25]

const SERVETARGETSPEED = 6

	
func Enter(athlete:Athlete):
	nameOfState="HumanServe"
	
	ball = athlete.ball
	serveState = ServeState.Walking
	serveTarget = athlete.get_tree().root.get_node("MatchScene").get_node("ServeTarget")
	serveUI = athlete.get_tree().root.get_node("MatchScene").get_node("UI/ServeUI")
	
	serveUI.humanServeState = self
	_athlete = athlete
	
	
	if rememberSettings:
		if rememberedServeTarget:
			serveTarget.position = rememberedServeTarget
		if rememberedServeType:
			serveType = rememberedServeType
			ChooseServeType(rememberedServeType)
		if rememberedServeAggression:
			serveAggression = rememberedServeAggression
			ChooseServeAggression(rememberedServeAggression)
		if rememberedWalkPosition:
			athlete.position = rememberedWalkPosition
	else:
		serveAggression = ServeAggression.UNDEFINED
		serveType = ServeType.UNDEFINED
		
	serveUI.ShowServeChoice()
		
#	if randi()%2 == 1:
#		serveType = ServeType.Float
#	else:
#		serveType = ServeType.Jump
	serveTarget.visible = false
	
func Update(athlete:Athlete):
	
	match serveState:
		ServeState.Walking:
			if Input.is_key_pressed(KEY_I):
				athlete.position.x -= athlete.myDelta * athlete.stats.speed
			if Input.is_key_pressed(KEY_J):
				athlete.position.z += athlete.myDelta * athlete.stats.speed
			if Input.is_key_pressed(KEY_L):
				athlete.position.z -= athlete.myDelta * athlete.stats.speed
			if Input.is_key_pressed(KEY_K):
				athlete.position.x += athlete.myDelta * athlete.stats.speed
			
			athlete.position.x = clamp(athlete.position.x, WALKBOUNDS[0],WALKBOUNDS[1])
			athlete.position.z = clamp(athlete.position.z, WALKBOUNDS[2],WALKBOUNDS[3])
			athlete.moveTarget = athlete.position
			
		ServeState.Aiming:
			if Input.is_key_pressed(KEY_I):
				serveTarget.position.x -= SERVETARGETSPEED * athlete.myDelta
			if Input.is_key_pressed(KEY_J):
				serveTarget.position.z += SERVETARGETSPEED * athlete.myDelta
			if Input.is_key_pressed(KEY_L):
				serveTarget.position.z -= SERVETARGETSPEED * athlete.myDelta
			if Input.is_key_pressed(KEY_K):
				serveTarget.position.x += SERVETARGETSPEED * athlete.myDelta
			
			#Aggressive jump serve can only be in the back 3 metres if you're not jumping a km into the air
			#Float and soft jump can realistically be anywhere past the 3 metre line
			#Underarm can go anywhere except the first 50cm without the Magnus Effect
			match serveType:
				ServeType.Jump:
					if serveAggression == ServeAggression.Aggressive:
						serveTarget.position.x = clamp(serveTarget.position.x, AGGRESSIVEJUMPBOUNDS[0], AGGRESSIVEJUMPBOUNDS[1])
						serveTarget.position.z = clamp(serveTarget.position.z, AGGRESSIVEJUMPBOUNDS[2], AGGRESSIVEJUMPBOUNDS[3])
					else:
						serveTarget.position.x = clamp(serveTarget.position.x, AGGRESSIVEJUMPBOUNDS[0], AGGRESSIVEJUMPBOUNDS[1])
						serveTarget.position.z = clamp(serveTarget.position.z, AGGRESSIVEJUMPBOUNDS[2], AGGRESSIVEJUMPBOUNDS[3])
				
				ServeType.Float:
					serveTarget.position.x = clamp(serveTarget.position.x, FLOATANDSOFTJUMPBOUNDS[0], FLOATANDSOFTJUMPBOUNDS[1])
					serveTarget.position.z = clamp(serveTarget.position.z, FLOATANDSOFTJUMPBOUNDS[2], FLOATANDSOFTJUMPBOUNDS[3])
				
				ServeType.Underarm:
					serveTarget.position.x = clamp(serveTarget.position.x, UNDERARMBOUNDS[0], UNDERARMBOUNDS[1])
					serveTarget.position.z = clamp(serveTarget.position.z, UNDERARMBOUNDS[2], UNDERARMBOUNDS[3])

			

			if Input.is_action_just_pressed("ui_accept"):
				
				CommenceServe()

		ServeState.Tossing:
			
			match serveType:
				ServeType.Jump:
					var runupLength = 2.75
					var runup = Vector2(attackTarget.x - athlete.position.x, attackTarget.z - athlete.position.z).normalized() * runupLength

					var jumpDistance = runup.normalized() * athlete.stats.verticalJump / 2


					#ball.Unparent()

					var tossTarget = Vector3(athlete.position.x + runup.x + jumpDistance.x, athlete.stats.spikeHeight, athlete.position.z + runup.y + jumpDistance.y)
					takeOffTarget = Vector3(athlete.position.x + runup.x, 0, athlete.position.z + runup.y)

					ball.freeze = false
					ball.position = Vector3(athlete.position.x, ball.position.y, athlete.position.z)
					ball.linear_velocity = ball.FindWellBehavedParabola(ball.position, tossTarget, athlete.stats.spikeHeight + 5)
					
					ball.rotation = Vector3.ZERO
					ball.angular_velocity = Vector3 ( randf_range(-.5,.5),randf_range(-.5,.5), randf_range(10,30))
					
					serveState = ServeState.WatchingTheBallInTheAir
				
				ServeType.Float:
					var runupLength = 1.25
					var runup = Vector2(attackTarget.x - athlete.position.x, attackTarget.z - athlete.position.z).normalized() * runupLength

					var jumpDistance = runup.normalized() * athlete.stats.verticalJump / 2
					#ball.Unparent()

					var tossTarget = Vector3(athlete.position.x + runup.x + jumpDistance.x, athlete.stats.spikeHeight, athlete.position.z + runup.y + jumpDistance.y)
					takeOffTarget = Vector3(athlete.position.x + runup.x, 0, athlete.position.z + runup.y)

					ball.freeze = false
					ball.position = Vector3(athlete.position.x, ball.position.y, athlete.position.z)
					ball.linear_velocity = ball.FindWellBehavedParabola(ball.position, tossTarget, athlete.stats.spikeHeight + 5)
					
					ball.rotation = Vector3.ZERO
					ball.angular_velocity = Vector3 ( randf_range(-.5,.5),randf_range(-.5,.5), randf_range(10,30))
					
					serveState = ServeState.WatchingTheBallInTheAir
				
				ServeType.Underarm:
					ball.freeze = false
					
					HitBall(athlete)
					serveState = ServeState.NotServing



		ServeState.WatchingTheBallInTheAir:
			#transform.rotation = Quaternion.RotateTowards(transform.rotation, Quaternion.LookRotation(MyMaths.xzVector(ball.attackTarget - transform.position)), 15 * Time.deltaTime);
			if (ball.TimeTillBallReachesHeight(athlete.stats.spikeHeight) <= athlete.CalculateTimeTillJumpPeak(takeOffTarget)):
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
				
				#Again, don't ask me why this is needed
				athlete.rb.linear_velocity = ball.FindWellBehavedParabola(athlete.position, landing, athlete.stats.verticalJump)
#				await athlete.get_tree().idle_frame
#				athlete.rb.linear_velocity = ball.FindWellBehavedParabola(athlete.position, landing, athlete.stats.verticalJump)
				
				serveState = ServeState.Jump
				#if (timeTillJumpPeak<= jumpAnimationTime)
				#anim.SetTrigger("jump");

		ServeState.Jump:
			#if athlete.rb.linear_velocity.y >0:
				if ball.linear_velocity.y < 0 && athlete.stats.spikeHeight >= ball.position.y:
					HitBall(athlete)

		ServeState.Landing:
			if (athlete.position.y <= 0.01 && athlete.rb.linear_velocity.y < 0):
				athlete.rb.freeze = true
				athlete.rb.gravity_scale = 0
				
				athlete.position.y = 0
				serveState = ServeState.Walking
				athlete.stateMachine.SetCurrentState(athlete.defendState)

func HitBall(athlete:Athlete):
	var serveRoll = randf_range(0, athlete.stats.serve)
	
	var topspin = 0
	# did they stuff up the serve?? 
	# skill ~ 30 - 70 ~.5
	# expecting 5 - 30% error rate, depending checked aggro, avg 10%
	
	var fuckupProb = .075
	match serveAggression:
		ServeAggression.Aggressive:
			fuckupProb *= 2
		ServeAggression.Safety:
			fuckupProb /= 2

	var roll = randf()
	Console.AddNewLine("fuckup prob: " + str(fuckupProb) + "|| roll: " + str(roll))
	if roll < fuckupProb:
		attackTarget = Vector3(randf_range(1, -8), 0, randf_range(10, 10))
		topspin = 0
		ball.linear_velocity = ball.FindParabolaForGivenSpeed(ball.position, attackTarget, 10 + 20 * randf(), false)
		ball.inPlay = false
		Console.AddNewLine("BAD SERVE. Serve Stat: " + str(athlete.stats.serve) + " Serve speed: " + str("%.1f" % (ball.linear_velocity.length() * 3.6)) + "km/h")
		ball.mManager.PointToTeamB()
	else:
		if serveType == ServeType.Float:
			ball.floating = true
		elif serveType == ServeType.Jump:
			topspin = randf_range(.5, 1.8)
		
		if serveType == ServeType.Underarm:
			ball.Serve(ball.position, attackTarget, 3.6, topspin)
		else:
			ball.Serve(ball.position, attackTarget, 2.6, topspin)
		Console.AddNewLine("Serve Stat: " + str(athlete.stats.serve) + " Serve speed: " + str("%.1f" % (ball.linear_velocity.length() * 3.6)) + "km/h")
		athlete.get_tree().get_root().get_node("MatchScene").BallOverNet(true)
		
		var difficultyOfReception = 0
		match serveAggression:
			ServeAggression.Aggressive:
				difficultyOfReception = randf_range(athlete.stats.serve * 2/3, athlete.stats.serve)
			ServeAggression.Moderate:
				difficultyOfReception = randf_range(athlete.stats.serve/3, athlete.stats.serve * 2/3)
			ServeAggression.Safety:
				difficultyOfReception = randf_range(0, athlete.stats.serve/3)
		
		ball.difficultyOfReception = difficultyOfReception
		Console.AddNewLine("Difficulty of serve: " + str(int(difficultyOfReception)), Color.DARK_SALMON)
	ball.TouchedByA()
	serveState = ServeState.Landing
func ChooseServeType(type):
	serveType = type
	if rememberSettings:
		rememberedServeType = type
		rememberedWalkPosition = _athlete.moveTarget
	
	serveState = ServeState.ChoosingServeAggression
	

	
	serveUI.HideServeChoice()
	

func ChooseServeAggression(aggression):
	serveAggression = aggression
	
	var serveInaccuracy = (100.0 - _athlete.stats.serve)/25
	
	if rememberSettings:
		rememberedServeAggression = aggression

	serveTarget.visible = true
	serveTarget.mesh.top_radius = serveInaccuracy
	serveTarget.mesh.bottom_radius = serveTarget.mesh.top_radius
	
	serveState = ServeState.Aiming
	if !rememberSettings || rememberedServeTarget == null:

		match serveType:
			ServeType.Jump:
				if serveAggression == ServeAggression.Aggressive:
					serveTarget.position.x = randf_range(AGGRESSIVEJUMPBOUNDS[0] + 1 + serveInaccuracy, AGGRESSIVEJUMPBOUNDS[1] - serveInaccuracy)
					serveTarget.position.z = randf_range(AGGRESSIVEJUMPBOUNDS[2] + 0.5 + serveInaccuracy, AGGRESSIVEJUMPBOUNDS[3] - 0.5 - serveInaccuracy)
				else:
					serveTarget.position.x = randf_range(FLOATANDSOFTJUMPBOUNDS[0] + 1 + serveInaccuracy, FLOATANDSOFTJUMPBOUNDS[1] - serveInaccuracy)
					serveTarget.position.z = randf_range(FLOATANDSOFTJUMPBOUNDS[2] + 0.5 + serveInaccuracy, FLOATANDSOFTJUMPBOUNDS[3] - 0.5 - serveInaccuracy)

			ServeType.Float:
					serveTarget.position.x = randf_range(FLOATANDSOFTJUMPBOUNDS[0] + 1 + serveInaccuracy, FLOATANDSOFTJUMPBOUNDS[1] - serveInaccuracy)
					serveTarget.position.z = randf_range(FLOATANDSOFTJUMPBOUNDS[2] + 0.5 + serveInaccuracy, FLOATANDSOFTJUMPBOUNDS[3] - 0.5 - serveInaccuracy)

			ServeType.Underarm:
					serveTarget.position.x = randf_range(UNDERARMBOUNDS[0] + 1 + serveInaccuracy, UNDERARMBOUNDS[1] - serveInaccuracy)
					serveTarget.position.z = randf_range(UNDERARMBOUNDS[2] + 0.5 + serveInaccuracy, UNDERARMBOUNDS[3] - 0.5 - serveInaccuracy)
	else:
		serveTarget.position = rememberedServeTarget
	
func CommenceServe():
	if rememberSettings:
		rememberedServeTarget = serveTarget.position
	#Add some variation based checked the lack of skill of the server
	#print("what if... : " + str(Vector2.ZERO.normalized()))
	var inaccuracy = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	var inaccuracyLength = randf_range(0, serveTarget.mesh.top_radius) # !!This is our nicely stored serveInaccuracy variable hashtag cleancode
	inaccuracy *= inaccuracyLength
	
	attackTarget = Vector3(serveTarget.position.x, 0, serveTarget.position.z)
	attackTarget.x += inaccuracy[0]
	attackTarget.z += inaccuracy[1]
	
	#If the ball is landing checked our side of the court? 
	#Players will expect it to occur given the target shows it as a possibility
	#For now just stop it happening
	
	attackTarget.x = clamp(attackTarget.x, -9999, -0.25)

	serveState = ServeState.Tossing
	serveTarget.visible = false
	
func Exit(__athlete:Athlete):
	pass
