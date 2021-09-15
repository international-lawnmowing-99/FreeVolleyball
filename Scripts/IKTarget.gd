extends Spatial

var realTarget

func _process(_delta):
	self.global_transform.origin = Vector3(realTarget.global_transform.origin.x, 0, realTarget.global_transform.origin.z)
	
