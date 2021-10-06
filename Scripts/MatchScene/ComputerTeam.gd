extends "res://Scripts/Team.gd"
class_name ComputerTeam



# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	flip = -1
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_TeamB_tree_exiting():

	pass # Replace with function body.
func _exit_tree():
	print("exiting")
