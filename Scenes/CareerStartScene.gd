class_name CareerStartScene
extends Node2D

@onready var teamChoice:TeamChoice = $ColourRect/BackgroundTeamChoice/VBoxContainer/TeamChoice
@onready var popup:PopupPanel = $ColourRect/Popup
# Called when the node enters the scene tree for the first time.
var gameWorld:GameWorld
var playerChoiceState:PlayerChoiceState

func _ready():
	gameWorld = GameWorld.new()
	gameWorld.GenerateDefaultWorld(false)
	playerChoiceState = PlayerChoiceState.new(gameWorld)
	teamChoice.Init(PreMatchUI.new(), gameWorld, playerChoiceState)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_accept_button_pressed():
	if teamChoice.ValidChoice():
		$ColourRect/Popup/VSplitContainer/PopupLabel.text = "You have chosen " + gameWorld.GetTeam(playerChoiceState, teamChoice.clubOrInternationalMode).teamName + ". Do you accept this binding choice that will haunt your destiny forever?"
		$ColourRect/Popup.popup()
		pass


func _on_confirm_button_pressed():
	# Write some info about the team choice somewhere?
	await get_tree().process_frame
	get_tree().change_scene_to_file("res://Scenes/ManagementScene/ManagementScene.tscn")


func _on_cancel_button_pressed():
	popup.hide()
