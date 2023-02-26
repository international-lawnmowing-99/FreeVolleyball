extends Node3D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
@onready var model = $fatcylinder/Cylinder
@onready var slider = $UI/HSlider

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	$fatcylinder.rotation.y += _delta
	pass


func _on_HSlider_value_changed(value):
	model.set("blend_shapes/Fatness", (float(2*value)-100)/100)
	pass # Replace with function body.
