extends Spatial



func ChangeShirtColour():
	var shirtMat = $"godette volleyball/Skeleton/godette volleyballfemale_casualsuit02".get_active_material(0)
	var newShirtMat = shirtMat.duplicate(false)
	$"godette volleyball/Skeleton/godette volleyballfemale_casualsuit02".set_surface_material(0, newShirtMat)
	newShirtMat.albedo_color = Color(3,3,3)
