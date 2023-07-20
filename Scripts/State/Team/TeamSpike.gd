extends "res://Scripts/State/Team/TeamState.gd"
class_name TeamSpike

var rng = RandomNumberGenerator.new()
var hit = false

func Enter(_team:Team):
	nameOfState = "Spike"
	rng.randomize()
	hit = false
	pass
func Update(team:Team):
	team.UpdateTimeTillDigTarget()
	if !hit && team.ball.linear_velocity.y <= 0 && team.ball.position.y <= team.chosenSpiker.stats.spikeHeight:
		if team.ball.linear_velocity.z > 0:
			if (team.ball.position.z > team.chosenSpiker.setRequest.target.z && \
			(team.ball.position - team.chosenSpiker.setRequest.target).length() < 0.5) &&\
			Maths.XZVector(team.ball.position - team.chosenSpiker.position).length() < 0.5:
				SpikeBall(team)
		elif team.ball.linear_velocity.z < 0:
			if (team.ball.position.z < team.chosenSpiker.setRequest.target.z &&\
				(team.ball.position - team.chosenSpiker.setRequest.target).length() < 0.5) &&\
				Maths.XZVector(team.ball.position - team.chosenSpiker.position).length() < 0.5:
					SpikeBall(team)
		else:
			Console.AddNewLine("No ball z vel...")
			if team.ball.position.x <= team.setTarget.target.x &&\
			(team.ball.position - team.chosenSpiker.setRequest.target).length() < 0.5:
				SpikeBall(team)

func Exit(_team:Team):
	pass

func SpikeBall(team:Team):
	var ball:Ball = team.ball
	if team.chosenSpiker.FrontCourt():
		ball.attackTarget = team.CheckIfFlipped(Vector3(-rng.randf_range(1, 9), 0, -4.5 + rng.randf_range(0, 9)))
	else:
		ball.attackTarget = team.CheckIfFlipped(Vector3(-rng.randf_range(6, 9), 0, -4.5 + rng.randf_range(0, 9)))
	if team.setTarget.height > 2.43:
		#Draw a line from the ball to the target. If the point where it crosses the 
		#net is higher than said net, it can be hit, otherwise roll
		var netPass:Vector3

		var distanceFactor:float = ball.position.x / (abs(ball.position.x) + abs(ball.attackTarget.x))
		if ball.position.x < 0:
			distanceFactor *= -1;

		netPass = ball.position + (ball.attackTarget - ball.position) * distanceFactor
		
		if netPass.y > 2.43:
			#var xzDistToTarget:float = (Vector3(ball.position.x, 0, ball.position.z) - Vector3(ball.attackTarget.x, 0, ball.attackTarget.z)).length()
			#var y = ball.position.y
			#var g = team.chosenSpiker.g
			
			#initial velocity of spike in mps
			var u = rng.randf_range(20,37)
			#print("Spike Speed(m/s): " + str(u))
			
			ball.difficultyOfReception = u/37.0*team.chosenSpiker.stats.spike*2
			
			ball.linear_velocity = ball.FindParabolaForGivenSpeed(ball.position, ball.attackTarget, u, false)
#			await team.get_tree().idle_frame
#			ball.linear_velocity = ball.FindParabolaForGivenSpeed(ball.position, ball.attackTarget, u, false)
			
		else:
			#yet again, somehow necessary
			ball.linear_velocity = ball.FindWellBehavedParabola(ball.position, ball.attackTarget,  max(2.8, team.setTarget.height + 0.5))
#			await team.get_tree().idle_frame
#			ball.linear_velocity = ball.FindWellBehavedParabola(ball.position, ball.attackTarget,  max(2.8, team.setTarget.height + 0.5))
			ball.difficultyOfReception = rng.randf_range(0, team.chosenSpiker.stats.spike/4)
			#team.setTarget = null
			#print(ball.attackTarget)
	else:
		#yet again, somehow necessary
		ball.linear_velocity = ball.FindWellBehavedParabola(ball.position, ball.attackTarget,  max(2.8, team.setTarget.height + 0.5))
#		await team.get_tree().idle_frame
#		ball.linear_velocity = ball.FindWellBehavedParabola(ball.position, ball.attackTarget,  max(2.8, team.setTarget.height + 0.5))
		ball.difficultyOfReception = rng.randf_range(0, team.chosenSpiker.stats.spike/4)
		team.setTarget = null
		
	# "#Efficiency"
	team.get_tree().get_root().get_node("MatchScene").BallSpiked(team.isHuman)
	hit = true
	# 9 court target segments
	# standard aggressive spike, tool unchecked block, tip, 
	
	Console.AddNewLine(team.chosenSpiker.stats.lastName + " cranks the ball at " + str("%.1f" % (ball.linear_velocity.length() * 3.6)) + "km/h")
	
