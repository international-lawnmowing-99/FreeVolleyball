extends Spatial

onready var anim = $AnimationPlayer2

func play_randomized(animation_name : String):
	randomize()
	anim.play(animation_name)
	var offset : float = rand_range(0, anim.current_animation_length)
	anim.advance(offset)

func _ready():
	play_randomized("Idle take 1")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
