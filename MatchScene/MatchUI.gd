extends Control
@onready var teamTacticsUICanvas = $TeamTacticsUICanvas
@onready var teamInfoUI = $TeamInfoUI
@onready var serveUI = $ServeUI
@onready var scoreUI = $ScoreCanvasLayer

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_toggle_team_tactics_ui_pressed():
	teamTacticsUICanvas.visible = !teamTacticsUICanvas.visible
	teamInfoUI.visible = !teamInfoUI.visible
	pass # Replace with function body.
