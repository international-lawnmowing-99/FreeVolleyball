extends Node2D

func _on_NewGameButton_pressed() -> void:
	$NewGameOptions.show()
	$NewGameButton.hide()
	$LoadButton.hide()
	$QuitButton.hide()



func _on_QuitButton_pressed() -> void:
	get_tree().quit()



func _on_HomeButton_pressed() -> void:
	$NewGameButton.show()
	$LoadButton.show()
	$QuitButton.show()
	$NewGameOptions.hide()



func _on_CustomMatchButton_pressed() -> void:
	pass # Replace with function body.


func _on_CareerButton_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/CareerStartScene.tscn")


func _on_QuickMatchButton_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/MatchScene/MatchScene.tscn")
	pass # Replace with function body.


func _on_LoadButton_pressed() -> void:
	$LoadButton/FileDialog.popup_centered()
	pass # Replace with function body.


func _on_FileDialog_file_selected(path: String) -> void:
	print(path)
	pass # Replace with function body.
