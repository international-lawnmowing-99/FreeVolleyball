extends CanvasLayer

var humanServeState

func ShowServeChoice():
	$ServeTypeButtons.show()
	pass

func HideServeChoice():
	$ServeTypeButtons.hide()

func ShowServeAggressionChoice():
	$ServeAggressionButtons.show()

func HideServeAggressionChoice():
	$ServeAggressionButtons.hide()
	humanServeState.CommenceServe()

#func _on_Button_pressed():
#	HideServeChoice()
#	pass # Replace with function body.


func _on_UnderArmButton_pressed():
	humanServeState.serveType = humanServeState.ServeType.Underarm
	HideServeChoice()
	ShowServeAggressionChoice()

func _on_JumpServeButton_pressed():
	humanServeState.serveType = humanServeState.ServeType.Jump
	HideServeChoice()
	ShowServeAggressionChoice()

func _on_FloatButton_pressed():
	humanServeState.serveType = humanServeState.ServeType.Float
	HideServeChoice()
	ShowServeAggressionChoice()


func _on_AggressiveServe_pressed() -> void:
	humanServeState.serveAggression = humanServeState.ServeAggression.Aggressive
	HideServeAggressionChoice()


func _on_ControlledServe_pressed() -> void:
	humanServeState.serveAggression = humanServeState.ServeAggression.Controlled
	HideServeAggressionChoice()

func _on_ModerateServe_pressed() -> void:
	humanServeState.serveAggression = humanServeState.ServeAggression.Moderate
	HideServeAggressionChoice()
