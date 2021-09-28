extends Spatial
class_name Athlete
#signal ballPassed



var role
var stats:Stats = Stats.new()

var stateMachine:StateMachine = load("res://Scripts/State/StateMachine.gd").new(self)
#onready var anim = $AnimationPlayer2

#onready var target = $Target
#onready var moveTargetModel = $"../MoveTarget"

onready var animTree = $AnimationTree

var ball:Ball
var skel:Skeleton

var spineBone01Id
var spineBone02Id
var neckBone01Id
var neckBone02Id

var customPose01
var customPose02
var customPoseNeck01
var customPoseNeck02

var basisz = transform.basis.z
var basisx = transform.basis.x
var anglewanted = transform.basis.y

var MAXSPEED = 13
var speed = 0
var acceleration = 10

var rotationSpeed = 8

var rotationPosition

#func play_randomized(animation_name : String):
	#randomize()
	#anim.play(animation_name)
	#var offset : float = rand_range(0, anim.current_animation_length)
	#anim.advance(offset)
var digAngle = 0
var timeTillBallReachesMe = 9999
var moveTarget = Vector3.ZERO
var servePos = Vector3.ZERO

func _ready():
	
	#DebugOverlay.draw.add_vector(self, "basisz", 1, 4, Color(0,1,0, 0.5))
	#DebugOverlay.draw.add_vector(self, "basisx", 1, 4, Color(1,1,0, 0.5))
	
	skel = get_node("godette volleyball/Skeleton")
	spineBone01Id = skel.find_bone("spine01")
	spineBone02Id = skel.find_bone("spine02")
	neckBone01Id = skel.find_bone("neck01")
	neckBone02Id = skel.find_bone("neck02")
	
	customPose01 = skel.get_bone_custom_pose(spineBone01Id)
	customPose02 = skel.get_bone_custom_pose(spineBone02Id)
	customPoseNeck01 = skel.get_bone_custom_pose((neckBone01Id))
	customPoseNeck02 = skel.get_bone_custom_pose((neckBone02Id))

	#print(spineBoneId)
	#Engine.time_scale = .1
	#play_randomized("Idle take 1")
	pass
func _physics_process(_delta):
#	if ball.translation.y < 1 && \
#		(Vector3(ball.translation.x,0, ball.translation.z)).distance_to(translation) < 1\
#		&& matchManager.gameState == MatchManager.GameState.Receive:
	#	if ball.translation.distance_to(self.translation) < 1 && matchManager.gameState == matchManager.GameState.Receive:
#			PassBall()
	pass
		
func _input(_event):
	#if event.is_action_pressed("ui_accept"):
	#	moveTarget = Vector3(rand_range(-13,13),0, rand_range(-13,13))
	#	moveTargetModel.translation = moveTarget + Vector3(0,0.1,0)
		
	pass
func _process(_delta):
	basisz = transform.basis.z
	basisx = transform.basis.x
	return
#	if matchManager.gameState == matchManager.GameState.Receive && ball.linear_velocity.x!=0:
#		timeTillBallReachesMe = Vector3(ball.translation.x, 0, ball.translation.z).distance_to(Vector3(translation.x, 0, translation.z))\
#				/Vector3(ball.linear_velocity.x, 0, ball.linear_velocity.z).length()
#		var animFactor = 1.3-  timeTillBallReachesMe 
#		animTree.set("parameters/BlendSpace1D/blend_position", animFactor)
#		RotateDigPlatform(lerp(0,digAngle,(min(1,1/timeTillBallReachesMe - 2))))
#	else:
#		var a = animTree.get("parameters/BlendSpace1D/blend_position")
#		animTree.set("parameters/BlendSpace1D/blend_position", lerp(a, 0, 5*_delta))
#		digAngle = lerp(digAngle,0,3*_delta)
#		RotateDigPlatform(digAngle)
	if translation.distance_squared_to(moveTarget)>0.01:
		Move(_delta)
	else: 
		speed = 0
		
func Move(delta):
	# For the future - measure the length, use it to determine if you should strafe or turn
	
	
	var distanceToTarget = translation.distance_to(moveTarget)
	var stoppingDistance = (speed * speed) / (2*acceleration)
	
	if stoppingDistance >= distanceToTarget && speed > acceleration * delta:
		speed -= acceleration * delta
		#rotation.y = lerp_angle(rotation.y, atan2(servePos.x - translation.x,servePos.z - translation.z), delta * rotationSpeed)
		
	
	elif(speed < MAXSPEED):
		#print ("accelerating " + "%10.2f" % speed + " | " + "%10.2f" %distanceToTarget +" | " + "%4.2f" %stoppingDistance)
		speed += acceleration * delta
		#rotation.y = lerp_angle(rotation.y, atan2(moveTarget.x - translation.x,moveTarget.z - translation.z), delta * rotationSpeed)
	
	#rotation_degrees += rotationSpeed * delta
	
	
	var moveVector = (moveTarget - translation).normalized()
	translation += moveVector * speed * delta
	
	animTree.set("parameters/BlendSpace2D/blend_position", Vector2(moveVector.x, moveVector.z))
	
	#rotate_y(deg2rad(rotationSpeed))
	pass
	
func PassBall():
	#Engine.time_scale = 0.25
	emit_signal("ballPassed")
	
	ball.linear_velocity = Vector3.ZERO
	ball.gravity_scale = 1

	ball.linear_velocity = (ball.FindWellBehavedParabola(ball.transform.origin, Vector3(-0.5, 2.5, 0), rand_range(3,7)))
	yield(get_tree(),"idle_frame")
	ball.linear_velocity = (ball.FindWellBehavedParabola(ball.transform.origin, Vector3(-0.5, 2.5, 0), rand_range(3,7)))

func RotateDigPlatform(angle):
	
	var acustomPose01 = customPose01.rotated(Vector3.UP, deg2rad(angle/2))
	var acustomPose02 = customPose02.rotated(Vector3.UP, deg2rad(angle/2))
	var acustomPoseNeck01 = customPoseNeck01.rotated(Vector3.UP, deg2rad(-angle/2))
	var acustomPoseNeck02 = customPoseNeck02.rotated(Vector3.UP, deg2rad(-angle/2))
	
	skel.set_bone_custom_pose(spineBone01Id, acustomPose01)
	skel.set_bone_custom_pose(spineBone02Id, acustomPose02)
	skel.set_bone_custom_pose(neckBone01Id, acustomPoseNeck01)
	skel.set_bone_custom_pose(neckBone02Id, acustomPoseNeck02)


func _on_ServingMachine_ballServed(_attackTarget, _servePos):
	moveTarget = ball.BallPositionAtGivenHeight(0.9) + Vector3(0,-.9, rand_range(-.5,.51))
	moveTarget += (moveTarget - Vector3(_servePos.x, 0, _servePos.z)).normalized()/2
#	moveTargetModel.translation = moveTarget
	servePos = _servePos  
	#look_at(Vector3(servePos.x,0, servePos.z), Vector3.UP)
	#rotate(Vector3.UP, PI)

	
	#var ballPassingV3 = ball.BallPositionAtGivenHeight(.85)
	#translation = attackTarget
	#var moveFactor = Vector3(ballPassingV3.x,0, ballPassingV3.z).distance_to( attackTarget)/1.5
	
	#translation -= transform.basis.z/2 # * moveFactor)
	
	#point where a circle will intersect with the xz vector of the ball's motion
	#circle is (x-h)^2 + (y-k)^2 = r^2
	var h = translation.x
	var k = translation.z
	var r = .66 #Dig radius is this much?
	#line is ...
	var xPart = ball.linear_velocity.x
	var zPart = ball.linear_velocity.z # (It's y!)
	
	
	
	
	var m
	if xPart == 0 && zPart == 0:
		pass
		#print("no vel to work with")
	elif zPart == 0:
		m = 0
		#print("m = 0")
	elif xPart == 0:
		m = 999999
		#print("m = big")
	else:
		m = zPart/xPart 
	#y=mx+b
	#b = y - mx
	var b = servePos.z - m * servePos.x
	
	#Will the two meet??
	# circle = line 
	
	var aDet = m*m + 1
	var bDet = -2*h + 2*m*b - 2*k*m
	var cDet = h*h + b*b + k*k -2*k*b - r*r
	
	var determinate = bDet * bDet - 4 *aDet * cDet
	
	var intersectionPointX
	
	if determinate == 0:
		#Congrats, you have a tangent
		intersectionPointX = (-bDet + sqrt(determinate))/(2*aDet)
	elif determinate > 0:
		# Choose t
		var point1x =  (-bDet + sqrt(determinate))/(2*aDet)
		var point2x = (-bDet - sqrt(determinate))/(2*aDet)
		intersectionPointX = max(point1x, point2x)
	else:
		# No intersections
		intersectionPointX = h +1
		#print("can't make that work chap")
		
	var intersectionPointZ = m*intersectionPointX + b
	
	#get_node("../target").translation =  Vector3(intersectionPointX,0,intersectionPointZ)
	
	digAngle = rad2deg(  ball.SignedAngle(transform.basis.z, -translation + Vector3(intersectionPointX,0,intersectionPointZ), Vector3.UP))

	anglewanted = - translation + Vector3(intersectionPointX,0,intersectionPointZ)

static func SortSet(a,b):
	if a.stats.SetterEvaluation() > b.stats.SetterEvaluation():
		return true
	return false

static func SortLib(a,b):
	if a.stats.LiberoEvaluation() > b.stats.LiberoEvaluation():
		return true
	return false

static func SortMiddle(a,b):
	if a.stats.MiddleEvaluation() > b.stats.MiddleEvaluation():
		return true
	return false

static func SortOpposite(a,b):
	if a.stats.OppositeEvaluation() > b.stats.OppositeEvaluation():
		return true
	return false

static func SortOutside(a,b):
	if a.stats.OutsideEvaluation() > b.stats.OutsideEvaluation():
		return true
	return false

func FrontCourt()->bool:
	if (rotationPosition == 1 || rotationPosition>4):
		return false
		
	else:
		return true
