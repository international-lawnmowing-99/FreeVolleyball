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
	Console.AddNewLine("Generating A Game World, have patience")
	await get_tree().create_timer(0.05).timeout
	var gam:GameWorld = GameWorld.new()
	gam.GenerateDefaultWorld(true)
	var savedGame:SavedCareer = SavedCareer.new()


	savedGame.gameWorld = gam
	savedGame.myTeamChoiceState = PlayerChoiceState.new(savedGame.gameWorld)


	savedGame.number = 13
	savedGame.string = "blah blah"

	GlobalVariables.savedGam = savedGame
	get_tree().change_scene_to_file("res://Scenes/CareerStartScene.tscn")


func _on_QuickMatchButton_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/MatchScene/MatchScene.tscn")



func _on_LoadButton_pressed() -> void:
	$LoadButton/FileDialog.popup_centered()



func _on_FileDialog_file_selected(path: String) -> void:
	print(path)
	var loadedCareer:SavedCareer = SavedCareer.LoadGame(path)

	GlobalVariables.savedGam = loadedCareer

	get_tree().change_scene_to_file("res://Scenes/ManagementScene/ManagementScene.tscn")

