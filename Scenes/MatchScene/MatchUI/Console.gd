extends CanvasLayer
var consoleLine = preload("res://Scenes/MatchScene/MatchUI/ConsoleLine.tscn")

@export var MAXLINES = 36
var existingLines:Array
func AddNewLine(text:String, colour:Color = Color.WHITE):
	print(text)
	var lineOfSuspiciousPowder = consoleLine.instantiate()
	existingLines.append(lineOfSuspiciousPowder)
	lineOfSuspiciousPowder.position = Vector2(50,841)
	lineOfSuspiciousPowder.text = text
	lineOfSuspiciousPowder.modulate = colour
	
	for line in get_children():
		line.position = Vector2(line.position.x, line.position.y - 20)
	add_child(lineOfSuspiciousPowder)
	
	if existingLines.size() > MAXLINES:
		#Don't have too many array elements...
		var lineToDelete = existingLines.pop_front()
		if is_instance_valid(lineToDelete):
			lineToDelete.queue_free()
		
func Clear():
	for child in get_children():
		child.queue_free()
