extends CanvasLayer
var consoleLine = preload("res://Scenes/MatchScene/MatchUI/ConsoleLine.tscn")



#func _input(_event):

func AddNewLine(text:String, colour:Color = Color.WHITE):
	print(text)
	var lineOfSuspiciousPowder = consoleLine.instantiate()
	lineOfSuspiciousPowder.position = Vector2(50,841)
	lineOfSuspiciousPowder.text = text
	lineOfSuspiciousPowder.modulate = colour
	
	for line in get_children():
		line.position = Vector2(line.position.x, line.position.y - 20)
	add_child(lineOfSuspiciousPowder)

func Clear():
	for child in get_children():
		child.queue_free()
