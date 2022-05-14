extends ColorRect
var consoleLine = preload("res://MatchScene/ConsoleLine.tscn")



func _input(_event):
	if Input.is_key_pressed(KEY_1):
		AddNewLine("Good serve by lad A")

func AddNewLine(text:String):
	var lineOfSuspiciousPowder = consoleLine.instance()
	lineOfSuspiciousPowder.rect_position = Vector2(0,741)
	lineOfSuspiciousPowder.text = text
	
	for line in get_children():
		line.rect_position = Vector2(line.rect_position.x, line.rect_position.y - 50)
	add_child(lineOfSuspiciousPowder)
