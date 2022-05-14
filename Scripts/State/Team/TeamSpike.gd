extends "res://Scripts/State/Team/TeamState.gd"
var rng = RandomNumberGenerator.new()


func Enter(team:Team):
	rng.randomize()
	pass
func Update(team:Team):
	team.UpdateTimeTillDigTarget()
	if team.ball.linear_velocity.z > 0:
		if (team.ball.translation.z > team.chosenSpiker.setRequest.target.z && \
		team.ball.linear_velocity.y <= 0 && \
		(team.ball.translation - team.chosenSpiker.setRequest.target).length() < 0.5):
			SpikeBall(team)
	elif (team.ball.translation.z < team.chosenSpiker.setRequest.target.z &&\
		 team.ball.linear_velocity.y <= 0 && \
		(team.ball.translation - team.chosenSpiker.setRequest.target).length() < 0.5):
			SpikeBall(team)

func Exit(team:Team):
	pass

func SpikeBall(team:Team):
	var ball:Ball = team.ball
	
	ball.attackTarget = team.CheckIfFlipped(Vector3(-rng.randf_range(1, 9), 0, -4.5 + rng.randf_range(0, 9)))

	if team.setTarget.height > 2.43:
		#Draw a line from the ball to the target. If the point where it crosses the 
		#net is higher than said net, it can be hit, otherwise roll
		var netPass:Vector3

		var distanceFactor:float = ball.translation.x / (abs(ball.translation.x) + abs(ball.attackTarget.x))
		if ball.translation.x < 0:
			distanceFactor *= -1;

		netPass = ball.translation + (ball.attackTarget - ball.translation) * distanceFactor
		
		if netPass.y > 2.43:
			#var xzDistToTarget:float = (Vector3(ball.translation.x, 0, ball.translation.z) - Vector3(ball.attackTarget.x, 0, ball.attackTarget.z)).length()
			#var y = ball.translation.y
			#var g = team.chosenSpiker.g
			
			#initial velocity of spike in mps
			var u = rng.randf_range(20,37)
			#print("Spike Speed(m/s): " + str(u))
			
			
			
			ball.linear_velocity = ball.FindParabolaForGivenSpeed(ball.translation, ball.attackTarget, u, false)
			yield(team.get_tree(),"idle_frame")
			ball.linear_velocity = ball.FindParabolaForGivenSpeed(ball.translation, ball.attackTarget, u, false)
			
			#print(ball.attackTarget)
	else:
		#yet again, somehow necessary
		ball.linear_velocity = ball.FindWellBehavedParabola(ball.translation, ball.attackTarget,  min(2.45, team.setTarget.height + 0.5))
		yield(team.get_tree(),"idle_frame")
		ball.linear_velocity = ball.FindWellBehavedParabola(ball.translation, ball.attackTarget,  min(2.45, team.setTarget.height + 0.5))
		ball.difficultyOfReception = team.chosenSpiker.stats.spike/4
		team.setTarget = null
		
	# "#Efficiency"
	team.get_tree().get_root().get_node("MatchScene").BallOverNet(team.isHuman)
	team.get_tree().root.find_node("MatchScene", true, false).console.AddNewLine(team.chosenSpiker.stats.lastName + " cranks the ball at " + str("%.1f" % (ball.linear_velocity.length() * 3.6)) + "km/h")
	
