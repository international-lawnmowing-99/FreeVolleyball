extends Control

class Vector:
	var object  # The node to follow

	var property  # The property to draw

	var scale  # Scale factor

	var width  # Line width

	var colour  # Draw colour


	func _init(_object, _property, _scale, _width, _colour):
		object = _object
		property = _property
		scale = _scale
		width = _width
		colour = _colour

	func draw(node, camera):
		var start = camera.unproject_position(object.global_transform.origin)
		var end = camera.unproject_position(object.global_transform.origin + object.get(property) * scale)
		node.draw_line(start, end, colour, width)
		#node.draw_triangle(end, start.direction_to(end), width*2, colour)

var vectors = []  # Array to hold all registered values.

func _process(_delta):
	if not visible:
		return
	update()
	
func draw_triangle(pos, dir, size, colour):
	var a = pos + dir * size
	var b = pos + dir.rotated(2*PI/3) * size
	var c = pos + dir.rotated(4*PI/3) * size
	var points = PoolVector2Array([a, b, c])
	#if !collinear(a,b,c):
	draw_polygon(points, PoolColorArray([colour]))

func _draw():
	var camera = get_viewport().get_camera()
	for vector in vectors:
		vector.draw(self, camera)
#func collinear(a,b,c):
	#if b - a == c-b:
	#	return true
	
	return false
func add_vector(object, property, scale, width, colour):
	vectors.append(Vector.new(object, property, scale, width, colour))
func _ready():
	print(self.get_path())
