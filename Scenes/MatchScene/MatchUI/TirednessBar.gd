extends ColorRect

class_name FreshnessBar

var startingWidth = 150

func _ready() -> void:
	startingWidth = $GreenBar.size.x
	#UpdateBar(randi()%50)

func UpdateBar(freshness):
	if freshness < 0 || freshness > 100:
		print("Error - he's literally given 110% and now has negative fitness...")
		assert(false)
		return
	$GreenBar.size.x = startingWidth * (freshness)/100
	pass
