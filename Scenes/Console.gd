extends CanvasLayer
var consoleLine = preload("res://MatchScene/ConsoleLine.tscn")



func _input(_event):
	if Input.is_key_pressed(KEY_1):
		AddNewLine("Good serve by lad A")

func AddNewLine(text:String, colour:Color = Color.white):
	var lineOfSuspiciousPowder = consoleLine.instance()
	lineOfSuspiciousPowder.rect_position = Vector2(0,841)
	lineOfSuspiciousPowder.text = text
	lineOfSuspiciousPowder.modulate = colour
	
	for line in get_children():
		line.rect_position = Vector2(line.rect_position.x, line.rect_position.y - 40)
	add_child(lineOfSuspiciousPowder)
