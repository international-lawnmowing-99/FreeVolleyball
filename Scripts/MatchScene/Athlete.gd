extends Spatial
class_name Athlete
#signal ballPassed
var g = ProjectSettings.get_setting("physics/3d/default_gravity")
var role
var stats:Stats = Stats.new()

var stateMachine:StateMachine = load("res://Scripts/State/StateMachine.gd").new(self)
#onready var anim = $AnimationPlayer2

#onready var target = $Target
#onready var moveTargetModel = $"../MoveTarget"

onready var animTree = $"new new woman import/AnimationTree"
onready var rb:RigidBody = $"."
onready var rbCollisionShape:CollisionShape = $CollisionShape
var team

var serveState
onready var defendState = load("res://Scripts/State/Athlete/AthleteDefendState.gd").new()
onready var passState = load("res://Scripts/State/Athlete/AthletePassState.gd").new()
onready var transitionState = load("res://Scripts/State/Athlete/AthleteTransitionState.gd").new()
onready var setState = load("res://Scripts/State/Athlete/AthleteSetState.gd").new()
onready var spikeState = load("res://Scripts/State/Athlete/AthleteSpikeState.gd").new()
onready var blockState = load("res://Scripts/State/Athlete/AthleteBlockState.gd").new()
onready var chillState = load("res://Scripts/State/Athlete/AthleteChillState.gd").new()

var blockingTarget:Athlete

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
var setRequest:Set

var middleSpikes
var outsideBackSpikes
var outsideFrontSpikes
var oppositeFrontSpikes
var oppositeBackSpikes

#because can't work out how to pass arguments to the sort_custom class
var distanceHack

func CreateSpikes():
	
	middleSpikes = [ Set.new(0.5, stats.spikeHeight, -0.5, stats.spikeHeight),
Set.new(0.5, stats.spikeHeight, -1.5, stats.spikeHeight+ 0.1),
Set.new(0.5, stats.spikeHeight, 0.5, stats.spikeHeight+ 0.1),
		]
	outsideFrontSpikes = [ Set.new(.5, stats.spikeHeight, -4.2, max(3, stats.spikeHeight + 1)),
Set.new(.5, stats.spikeHeight, -2.75, 3.5),
Set.new(.5, stats.spikeHeight, -1, 3.43)
		]
	outsideBackSpikes = [ Set.new(2, stats.spikeHeight, -1, max(3, stats.spikeHeight + .5)),
Set.new(2.5, stats.spikeHeight, 1, 3.8)
]
	oppositeFrontSpikes = [ Set.new(.5, stats.spikeHeight, 4.5, max(3, stats.spikeHeight + 1)),
Set.new(.4, stats.spikeHeight, 1, 13.43),
Set.new(.4, stats.spikeHeight, 4.2, 13.8)
]
	oppositeBackSpikes = [ Set.new(2.5, stats.spikeHeight, 4.2, max(3, stats.spikeHeight + 1)),
Set.new(2.5, stats.spikeHeight, 1, 3.8),
]

func _ready():
	CreateSpikes()
	
	#DebugOverlay.draw.add_vector(self, "basisz", 1, 4, Color(0,1,0, 0.5))
	#DebugOverlay.draw.add_vector(self, "basisx", 1, 4, Color(1,1,0, 0.5))
	
	skel = get_node("new new woman import/godette volleyball/Skeleton")
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


	pass
func _process(_delta):
	if stateMachine.currentState:
		stateMachine.currentState.Update(self)
	BaseMove(_delta)
	basisz = transform.basis.z
	basisx = transform.basis.x
	return


#		var animFactor = 1.3-  timeTillBallReachesMe 
#		animTree.set("parameters/BlendSpace1D/blend_position", animFactor)
#		RotateDigPlatform(lerp(0,digAngle,(min(1,1/timeTillBallReachesMe - 2))))
#	else:
#		var a = animTree.get("parameters/BlendSpace1D/blend_position")
#		animTree.set("parameters/BlendSpace1D/blend_position", lerp(a, 0, 5*_delta))
#		digAngle = lerp(digAngle,0,3*_delta)
#		RotateDigPlatform(digAngle)
	#if translation.distance_squared_to(moveTarget)>0.01:
		#Move(_delta)
	#else: 
	#	speed = 0
		
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

static func SortDistance(a,b):
	#It's min distance 
	if a.distanceHack < b.distanceHack:
		return true
	return false

func FrontCourt()->bool:
	if (rotationPosition == 1 || rotationPosition>4):
		return false
		
	else:
		return true

func CalculateTimeTillJumpPeak(takeOffXZ):
	var timeTillJumpPeak
	if rb.mode == RigidBody.MODE_KINEMATIC:
	
		var runupTime
		var jumpTime
		var runupDist

		runupDist = Vector3(translation.x, 0, translation.z).distance_to(takeOffXZ)
		runupTime = runupDist / stats.speed

		var jumpYVel = sqrt(2 * g * stats.verticalJump)
		jumpTime = jumpYVel / g

		timeTillJumpPeak = runupTime + jumpTime
	
	else:
	
		timeTillJumpPeak = -rb.linear_velocity.y / g
	
	return timeTillJumpPeak


func BaseMove(_delta):
	if rb.mode == RigidBody.MODE_KINEMATIC && translation.distance_to(moveTarget) > .1:
		var dir = (moveTarget - translation).normalized()
		translation += dir * stats.speed * _delta
		if translation.x != moveTarget.x:
			look_at_from_position(translation, moveTarget, Vector3.UP)
			rotate_y(PI)
	#else:
	#	moveTarget = Vector3(rand_range(-20,20), 0, rand_range(-20,20))
