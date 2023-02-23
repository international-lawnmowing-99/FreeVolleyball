extends CanvasLayer
var consoleLine = preload("res://MatchScene/ConsoleLine.tscn")



#func _input(_event):

func AddNewLine(text:String, colour:Color = Color.white):
	print(text)
	var lineOfSuspiciousPowder = consoleLine.instance()
	lineOfSuspiciousPowder.rect_position = Vector2(50,841)
	lineOfSuspiciousPowder.text = text
	lineOfSuspiciousPowder.modulate = colour
	
	for line in get_children():
		line.rect_position = Vector2(line.rect_position.x, line.rect_position.y - 20)
	add_child(lineOfSuspiciousPowder)

func Clear():
	for child in get_children():
		child.queue_free()
