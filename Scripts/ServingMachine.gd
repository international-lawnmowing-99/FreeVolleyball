extends Node

onready var ball:RigidBody = get_node("../ball")
onready var targetModel = get_node("../target")
var topspinFactor = 2
var g = ProjectSettings.get_setting("physics/3d/default_gravity") 
func _process(_delta):
	if Input.is_action_just_pressed("ui_accept"):
		LaunchBall()
		
func LaunchBall():
	if !ball:
		print("no balls")
	else:
		
		var topspin = rand_range(.5,1.8)
		ball.gravity_scale = 1 + topspin
		g = ProjectSettings.get_setting("physics/3d/default_gravity") * (1+topspin)
		
		ball.rotation = Vector3.ZERO
		ball.angular_velocity = Vector3 ( rand_range(-.5,.5),rand_range(-.5,.5), topspin * 80)
		ball.linear_velocity = Vector3.ZERO
		
		ball.translation = self.translation + Vector3(0,rand_range(3.4,3.5),0)
		print (str(ball.translation.y) + " height, " + str(topspin) + " topspin")
		var attackTarget = Vector3(rand_range(-1,-9), 0, rand_range(-4.5,4.5))
		targetModel.translation = attackTarget
		var height = rand_range(0,1)
		var impulse = CalculateBallOverNetVelocity(ball.translation, attackTarget, 2.6)
		impulse *= ball.mass
		ball.apply_central_impulse(impulse)
		print(str(impulse.length()*3.6))
		#Engine.time_scale = .2
	#ball.position = self.transform.translation + Vector3(0,2,0)
	#ball.apply_central_impulse(Vector3(0,5,2))
	
	# I'm serving. I want to hit a target with maximum speed. 
	# To hit the target I can vary my angle and speed. 
	# What is the max speed that will still clear the net? 
	# If the speed/release point combo is such that the parabola peaks before or at the net then it's just the 
	
func FindWellBehavedParabola(startPos: Vector3,endPos: Vector3, maxHeight:float):
	if maxHeight <= startPos.y || maxHeight < endPos.y:
		print("impossible parabola")
		return Vector3.ZERO
	
	var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
	var xzDist = Vector3(startPos.x, 0, startPos.z).distance_to(Vector3(endPos.x,0, endPos.z))
	var yVel = abs(sqrt(2 * gravity * (maxHeight - startPos.y)));
	
	var time = yVel / gravity + sqrt(2 * gravity * (maxHeight - endPos.y)) / gravity
	var xzVel = xzDist / time
	
	var xzTheta = SignedAngle(Vector3(1,0,0), Vector3(endPos.x, 0, endPos.z) - Vector3(startPos.x, 0, startPos.z), Vector3.UP)
	
	return Vector3(xzVel * cos(-xzTheta), yVel, xzVel * sin(-xzTheta))

func FindParabolaForGivenSpeed(startPos:Vector3, target:Vector3, speed:float, aimingUp:bool):
	var xzDirection = target - startPos;
	xzDirection.y = 0;

	var xzDist = Vector3(startPos.x, 0, startPos.z).distance_to(Vector3(target.x, 0, target.z))
	var yDist =  target.y - startPos.y;

	var idealAngle
	var angle1
	var angle2
	
	var determinant = pow(speed, 4) - g * (g * xzDist * xzDist + 2 * yDist * speed * speed)
	if determinant < 0:
		idealAngle = 45
	else:
		angle1 = atan((speed * speed + sqrt(determinant)) / (g * xzDist))
		angle2 = atan((speed * speed - sqrt(determinant)) / (g * xzDist));

		if aimingUp:
			idealAngle = max(angle1, angle2)
		else:
			idealAngle = min(angle1, angle2)

	var projectileVelocity:Vector3
	projectileVelocity.y = speed * sin(idealAngle)
	var xzProjectileVel = speed * cos(idealAngle)

	xzDirection = xzDirection.normalized()

	projectileVelocity.x = xzDirection.x * xzProjectileVel
	projectileVelocity.z = xzDirection.z * xzProjectileVel

	return projectileVelocity

func CalculateBallOverNetVelocity(startPos:Vector3, target:Vector3, heightOverNet:float):

	var distanceFactor = startPos.x / (abs(startPos.x) + abs(target.x))
	if startPos.x < 0:
		distanceFactor *= -1;

	var netPass:Vector3 = startPos + (target - startPos) * distanceFactor;
	netPass.y = heightOverNet

	var xzDistToTarget = Vector3(startPos.x, 0, startPos.z).distance_to(Vector3(target.x, 0, target.z))
	var xzDistToNet = Vector3(target.x, 0, target.z).distance_to(Vector3(netPass.x, 0, netPass.z))


#angle the ball wil be received on. I now have no idea how this formula was derived
	var theta = atan((netPass.y * xzDistToTarget * xzDistToTarget - startPos.y * xzDistToNet * xzDistToNet) / (xzDistToNet * xzDistToTarget * xzDistToTarget - xzDistToTarget * xzDistToNet * xzDistToNet))

#final vel(in reverse)
	var determinant = g * xzDistToNet * xzDistToTarget * (xzDistToTarget - xzDistToNet) * (1 + tan(theta) * tan(theta)) / (2 * (xzDistToTarget * netPass.y - xzDistToNet * startPos.y))
#this will happen if the middle point is lower than or equal to the straight-line point at the net of the start and end, ie the parabola curves the wrong way
	if determinant < 0:
		print("Can't make that work chap")
		return Vector3.ZERO
		
	var vel = sqrt(determinant)

#Calculate new y vel
	var xzVel = cos(theta) * vel
	var time = xzDistToTarget / xzVel

	var finalYVel = -(sin(theta) * vel - g * time);


	var xzTheta = SignedAngle(Vector3(1, 0, 0), Vector3(target.x, 0, target.z) - Vector3(startPos.x, 0, startPos.z), Vector3.UP)
	#xzTheta *= Mathf.Deg2Rad;

	var velocity = Vector3(vel * cos(theta) * cos(-xzTheta), finalYVel, vel * cos(theta) * sin(-xzTheta))
	return velocity

func SignedAngle(from, to, up):
	var cross_to = from.cross(to);
	var unsigned_angle = atan2(cross_to.length(), from.dot(to));
	var theSign = cross_to.dot(up);
	if theSign < 0:
		return -unsigned_angle
	else:
		return unsigned_angle
