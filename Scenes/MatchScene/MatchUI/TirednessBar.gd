extends ColorRect

var startingWidth = 150

func _ready() -> void:
	startingWidth = $GreenBar.size.x
	UpdateBar(randi()%50)
	
func UpdateBar(tiredness):
	if tiredness < 0 || tiredness > 100:
		print("Error - he's literally given 110% and now has negative fitness...")
		return
	$GreenBar.size.x = startingWidth * (100 - tiredness)/100
	pass
