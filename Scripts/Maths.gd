extends Node

func XZVector(vec:Vector3) -> Vector3:
	return Vector3(vec.x, 0, vec.z)

func SignedAngle(from:Vector3, to:Vector3, up:Vector3):
	if from == to or from == up or up == to:
		print("signed angle issue(?)")
		print("from: " + str(from)) 
		print("to: " + str(to)) 
		print("up: " + str(up)) 
		return 0.001
	var cross_to = from.cross(to)
	var unsigned_angle = atan2(cross_to.length(), from.dot(to))
	var theSign = cross_to.dot(up)
	
	if theSign < 0:
		return -unsigned_angle
	else:
		return unsigned_angle
