extends Node

#signal ballServed

@onready var ball:RigidBody3D = get_node("../ball")
@onready var targetModel = get_node("../new new woman")
@onready var attackTargetModel = get_node("../target")
@onready var posAt12 = get_node("../target2")



func _ready():
	#Engine.time_scale = 0.2
	return
	targetModel.get_node("Target").realTarget = ball
	targetModel.ball = ball
	targetModel.matchManager = get_node("../")
	randomize()
	pass


func _process(_delta):
	if Input.is_action_just_pressed("ui_accept"):
		self.position = Vector3(randf_range(7.9,9),.5,randf_range(-4.5,4.5))
		LaunchBall()
		
func LaunchBall():
	if !ball:
		print("no balls")
	else:
		var topspin = randf_range(.5,1.8)
		var attackTarget = Vector3(randf_range(-1,-9), 0, randf_range(-4.5,4.5))
		ball.position = self.position + Vector3(0,randf_range(3.4,3.5),0)
		ball.Serve(ball.position, attackTarget, topspin)
		

		#print(str(impulse.length()*3.6))
		
		emit_signal("ballServed", attackTarget, ball.position)
		attackTargetModel.position = attackTarget
