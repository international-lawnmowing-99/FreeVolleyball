extends Node3D
class_name Athlete

var g = ProjectSettings.get_setting("physics/3d/default_gravity")
var role
var stats:Stats = Stats.new()

var stateMachine:StateMachine = load("res://Scripts/State/StateMachine.gd").new(self)


@onready var animTree = $"new new woman import/AnimationTree"
@onready var rb:RigidBody3D = $"."
@onready var leftIK:SkeletonIK3D = $"new new woman import/godette volleyball/Skeleton3D/LeftHandSkeletonIK"
@onready var rightIK:SkeletonIK3D = $"new new woman import/godette volleyball/Skeleton3D/RightHandSkeletonIK"
@onready var leftIKTarget:Marker3D = $"new new woman import/LeftHandTarget"
@onready var rightIKTarget:Marker3D = $"new new woman import/RightHandTarget"

var team: Team
var myDelta:float
var serveState
@onready var defendState:AthleteDefendState = load("res://Scripts/State/Athlete/AthleteDefendState.gd").new()
@onready var passState:AthletePassState = load("res://Scripts/State/Athlete/AthletePassState.gd").new()
@onready var transitionState:AthleteTransitionState = load("res://Scripts/State/Athlete/AthleteTransitionState.gd").new()
@onready var setState:AthleteSetState = load("res://Scripts/State/Athlete/AthleteSetState.gd").new()
@onready var spikeState:AthleteSpikeState = load("res://Scripts/State/Athlete/AthleteSpikeState.gd").new()
@onready var blockState:AthleteBlockState = load("res://Scripts/State/Athlete/AthleteBlockState.gd").new()
@onready var freeBallState:AthleteFreeBallState = load("res://Scripts/State/Athlete/AthleteFreeBallState.gd").new()
@onready var chillState:AthleteChillState = load("res://Scripts/State/Athlete/AthleteChillState.gd").new()
@onready var coverState:AthleteCoverState = load("res://Scripts/State/Athlete/AthleteCoverState.gd").new()

const MoveDistanceDelta:float = 0.1

var ball:Ball
@onready var skel:Skeleton3D = $"new new woman import/godette volleyball/Skeleton3D"

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
#var anglewanted = transform.basis.y

var MAXSPEED = 13
var speed = 0
var acceleration = 10

var rotationSpeed = 8

var rotationPosition:int
var pseudoRotationPosition:int

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
	var targetXFrontcourt = stats.spikeHeight/2 + 0.15
	middleSpikes = [ Set.new(targetXFrontcourt, stats.spikeHeight, 0.5, stats.spikeHeight + 0.05),
Set.new(targetXFrontcourt, stats.spikeHeight, 1.5, stats.spikeHeight+ 0.05),
Set.new(targetXFrontcourt, stats.spikeHeight, -0.5, stats.spikeHeight+ 0.05)]
		
	outsideFrontSpikes = [ Set.new(targetXFrontcourt, stats.spikeHeight, 7.2, max(6, stats.spikeHeight + 1)),
Set.new(targetXFrontcourt, stats.spikeHeight, -2.75, 3.5),
Set.new(targetXFrontcourt, stats.spikeHeight, -1, 3.43)]

	outsideBackSpikes = [ Set.new(max(0.1 + stats.verticalJump/2, 3.1-stats.verticalJump/2), stats.spikeHeight, 1, max(3, stats.spikeHeight + .5)),
Set.new(max(0.1 + stats.verticalJump/2, 3.1-stats.verticalJump/2), stats.spikeHeight, -1, max(3, stats.spikeHeight + .5))]

	oppositeFrontSpikes = [ Set.new(targetXFrontcourt, stats.spikeHeight, -4.2, max(6, stats.spikeHeight + 1)),
Set.new(targetXFrontcourt, stats.spikeHeight, 1, 13.43),
Set.new(targetXFrontcourt, stats.spikeHeight, 4.2, 13.8)]

	oppositeBackSpikes = [ Set.new(max(0.1 + stats.verticalJump/2, 3.1-stats.verticalJump/2), stats.spikeHeight, -4.2, max(3, stats.spikeHeight + 1)),
Set.new(max(0.1 + stats.verticalJump/2, 3.1-stats.verticalJump/2), stats.spikeHeight, 1, max(3, stats.spikeHeight + 1))]

	for _set in middleSpikes:
		_set.CheckFlipped(team)
		
	for _set in outsideBackSpikes:
		_set.CheckFlipped(team)
		
	for _set in outsideFrontSpikes:
		_set.CheckFlipped(team)
		
	for _set in oppositeBackSpikes:
		_set.CheckFlipped(team)
		
	for _set in oppositeFrontSpikes:
		_set.CheckFlipped(team)
		
func _ready():
	#DebugOverlay.draw.add_vector(self, "basisz", 1, 4, Color(0,1,0, 0.5))
	#DebugOverlay.draw.add_vector(self, "basisx", 1, 4, Color(1,1,0, 0.5))

	
	spineBone01Id = skel.find_bone("spine01")
	spineBone02Id = skel.find_bone("spine02")
	neckBone01Id = skel.find_bone("neck01")
	neckBone02Id = skel.find_bone("neck02")
	
	
	customPose01 = skel.get_bone_global_pose(spineBone01Id)
	customPose02 = skel.get_bone_global_pose(spineBone02Id)
	customPoseNeck01 = skel.get_bone_global_pose(neckBone01Id)
	customPoseNeck02 = skel.get_bone_global_pose(neckBone02Id)
	

func _process(_delta):
	myDelta = _delta
#	if _delta <= 0.0:
#		print("quick frame!")
#	print(stats.lastName + " :: " + str(rotationPosition))
	if stateMachine.currentState:
		stateMachine.currentState.Update(self)
	BaseMove(_delta)
	basisz = transform.basis.z
	basisx = transform.basis.x
	
#	rb.linear_velocity = Vector3(0,-1,0)
#	rb.freeze = false
#	if transform.origin.y < -0.2:
#		print(stateMachine.currentState.nameOfState)
	
func DontFallThroughFloor():
	if !rb.freeze && position.y < 0.05 && rb.linear_velocity.y < 0:
		rb.freeze = true
		rb.gravity_scale = 0
		rb.linear_velocity = Vector3.ZERO
		position.y = 0
		#athlete.rotation = Vector3.ZERO
		rb.angular_velocity = Vector3.ZERO

func Move(delta):
	# For the future - measure the length, use it to determine if you should strafe or turn
	
	
	var distanceToTarget = position.distance_to(moveTarget)
	var stoppingDistance = (speed * speed) / (2*acceleration)
	
	if stoppingDistance >= distanceToTarget && speed > acceleration * delta:
		speed -= acceleration * delta
		#rotation.y = lerp_angle(rotation.y, atan2(servePos.x - position.x,servePos.z - position.z), delta * rotationSpeed)
		
	
	elif(speed < MAXSPEED):
		#print ("accelerating " + "%10.2f" % speed + " | " + "%10.2f" %distanceToTarget +" | " + "%4.2f" %stoppingDistance)
		speed += acceleration * delta
		#rotation.y = lerp_angle(rotation.y, atan2(moveTarget.x - position.x,moveTarget.z - position.z), delta * rotationSpeed)
	
	#rotation_degrees += rotationSpeed * delta
	
	
	var moveVector = (moveTarget - position).normalized()
	position += moveVector * speed * delta
	

	
	#rotate_y(deg_to_rad(rotationSpeed))
	pass
	
func RotateDigPlatform(angle):
#	It looks like zero angles here might have been a(!) cause of teh infamous "set_axis_angle: The axis Vector3 must be normalized." bug
	if angle == 0.0:
		angle = 0.01
	var acustomPose01 = customPose01.rotated(Vector3.UP, (angle/2))
	var acustomPose02 = customPose02.rotated(Vector3.UP, (angle/2))
#	var acustomPoseNeck01 = customPoseNeck01.rotated(Vector3.UP, (-angle/2))
#	var acustomPoseNeck02 = customPoseNeck02.rotated(Vector3.UP, (-angle/2))
	
	skel.set_bone_global_pose_override(spineBone01Id, acustomPose01,1.0)
	skel.set_bone_global_pose_override(spineBone02Id, acustomPose02,1.0)
#	skel.set_bone_global_pose_override(neckBone01Id, acustomPoseNeck01,1.0)
#	skel.set_bone_global_pose_override(neckBone02Id, acustomPoseNeck02,1.0)

static func SortSet(a,b):
	if a.stats.SetterEvaluation() > b.stats.SetterEvaluation():
		return true
	return false

static func SortLibero(a,b):
	if a.stats.LiberoEvaluation() > b.stats.LiberoEvaluation():
		return true
	return false

static func SortSkill(a,b):
	if a.stats.SkillTotal() > b.stats.SkillTotal():
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
	if rb.freeze:
		
		var runupTime
		var jumpTime
		var runupDist
		
		runupDist = Vector3(position.x, 0, position.z).distance_to(takeOffXZ)
		runupTime = runupDist / stats.speed

		var jumpYVel = sqrt(2 * g * stats.verticalJump)
		jumpTime = jumpYVel / g

		timeTillJumpPeak = runupTime + jumpTime
	
	elif rb.linear_velocity.y < 0:
		timeTillJumpPeak = -rb.linear_velocity.y / g
	else:
		timeTillJumpPeak = 0
		
	
	
	return timeTillJumpPeak

func BaseMove(_delta):
	if rb.freeze && position.distance_to(moveTarget) > MoveDistanceDelta:
		var dir = (moveTarget - position).normalized()
		position += dir * stats.speed * _delta
		animTree.set("parameters/MoveTree/blend_position", Vector2(dir.x, dir.z))
		if abs(position.x - moveTarget.x) > .3 && abs(position.z - moveTarget.z) > .3:
			$"new new woman import".look_at_from_position(Maths.XZVector(position), moveTarget, Vector3.UP, true)
			#rotate_y(PI)
	elif position != moveTarget && position.distance_to(moveTarget) <= MoveDistanceDelta:
		position = moveTarget
			
func ReEvaluateState():
	if rb.freeze:
		match team.stateMachine.currentState:
			team.receiveState:
				stateMachine.SetCurrentState(transitionState)
			team.setState:
				if team.chosenSetter == self:
						stateMachine.SetCurrentState(setState)
				else:
					stateMachine.SetCurrentState(transitionState)
			team.spikeState:
				if stateMachine.currentState.nameOfState == "Set":
					rotation.y = -team.flip*PI/2
					stateMachine.SetCurrentState(defendState)
				elif stateMachine.currentState.nameOfState == "Spike":
					#stateMachine.SetCurrentState(coverState)
					pass
				else:
					stateMachine.SetCurrentState(spikeState)
			team.defendState:
				if FrontCourt():
					stateMachine.SetCurrentState(blockState)
				else:
					stateMachine.SetCurrentState(defendState)
	else: 
		if position.y < 0:
			rb.freeze = true
			position.y = 0
			ReEvaluateState()
			Console.AddNewLine("recursive reevaluate: " + stats.lastName, Color.BLACK)
