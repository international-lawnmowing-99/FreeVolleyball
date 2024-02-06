extends Node3D
class_name ModelOfAthlete

@onready var originalShirtMat = $"godette volleyball/Skeleton3D/godette volleyball_female_casualsuit02".get_active_material(0)

func ChangeShirtColour(colour = Color(3,3,3)): 
	var newShirtMat = originalShirtMat.duplicate(false)
	$"godette volleyball/Skeleton3D/godette volleyball_female_casualsuit02".set_surface_override_material(0, newShirtMat)
	newShirtMat.albedo_color = colour

func RevertShirtColour():
	$"godette volleyball/Skeleton3D/godette volleyball_female_casualsuit02".set_surface_override_material(0, originalShirtMat)
