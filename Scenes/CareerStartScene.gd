class_name CareerStartScene
extends Node2D

@onready var teamChoice:TeamChoice = $ColourRect/BackgroundTeamChoice/VBoxContainer/TeamChoice
@onready var popup:PopupPanel = $ColourRect/Popup
# Called when the node enters the scene tree for the first time.
var gameWorld:GameWorld


func _ready():
	if !GlobalVariables.savedGam:
		Console.AddNewLine("Error! No game world!")
		return
	gameWorld = GlobalVariables.savedGam.gameWorld

	teamChoice.Init(PreMatchUI.new(), gameWorld, PlayerChoiceState.new(gameWorld))



func _on_accept_button_pressed():
	if teamChoice.ValidChoice():
		var team:TeamData = gameWorld.GetTeam(teamChoice.choiceState, teamChoice.clubOrInternationalMode)
		$ColourRect/Popup/VSplitContainer/PopupLabel.text = "You have chosen " + team.teamName + ". Do you accept this binding choice that will haunt your destiny forever?"
		$ColourRect/Popup.popup()
		pass


func _on_confirm_button_pressed():
	GlobalVariables.savedGam.myTeamChoiceState = teamChoice.choiceState
	GlobalVariables.savedGam.isClubOrInternational = teamChoice.clubOrInternationalMode

	for continent:Continent in GlobalVariables.savedGam.gameWorld.continents:
		for nation:Nation in continent.nations:

			var tournament:Tournament = Tournament.new()

			tournament.CreateRoundRobin(nation.league,999,1,GlobalVariables.savedGam.gameWorld.inGameUnixDate)
			GlobalVariables.savedGam.gameWorld.upcomingMatches += tournament.listOfMatches



	Console.AddNewLine("Saving, have patience")



	await get_tree().create_timer(0.05).timeout
	GlobalVariables.savedGam.SaveGame()
	get_tree().change_scene_to_file("res://Scenes/ManagementScene/ManagementScene.tscn")


func _on_cancel_button_pressed():
	popup.hide()


func _on_random_button_pressed():
	GlobalVariables.savedGam.isClubOrInternational = (randi()%2 + 1) as Enums.ClubOrInternational

	var playerChoiceState:PlayerChoiceState = PlayerChoiceState.new(gameWorld)
	playerChoiceState = playerChoiceState.ChooseRandom(gameWorld, GlobalVariables.savedGam.isClubOrInternational)
	GlobalVariables.savedGam.myTeamChoiceState = playerChoiceState

	teamChoice.DisplayNewChoiceState(playerChoiceState, GlobalVariables.savedGam.isClubOrInternational)
