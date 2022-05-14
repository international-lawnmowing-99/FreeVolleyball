extends Label

export var fadeSpeed:float = .13

func _ready():
	self_modulate.a = 1

func _process(delta):
	self_modulate.a -= fadeSpeed * delta
	
	if self_modulate.a < 0.01:
		queue_free()
