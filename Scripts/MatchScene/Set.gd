extends Node

class_name Set

var height:float
var target:Vector3

func _init(x,y,z,h):
	height = h
	target = Vector3(x,y,z)
	
func CheckFlipped(team):
	target.x *= team.flip
	target.z *= team.flip
