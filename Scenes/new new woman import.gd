extends Node3D



func ChangeShirtColour(colour = Color(3,3,3)):
	var shirtMat = $"godette volleyball/Skeleton3D/godette volleyball_female_casualsuit02".get_active_material(0)
	var newShirtMat = shirtMat.duplicate(false)
	$"godette volleyball/Skeleton3D/godette volleyball_female_casualsuit02".set_surface_override_material(0, newShirtMat)
	newShirtMat.albedo_color = colour
