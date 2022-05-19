extends CanvasLayer

onready var matchIntro = $ColourRect
onready var teamSelection = $TeamSelectionUI
func _on_Button_pressed():
	matchIntro.hide()
	teamSelection.show()
	pass # Replace with function body.
