extends Control
@onready var teamTacticsUICanvas = $TeamTacticsUICanvas
@onready var matchStatsUI = $TeamInfoUI/StatsViewerUI
@onready var teamInfoUI = $TeamInfoUI
@onready var serveUI = $ServeUI
@onready var scoreUI = $ScoreCanvasLayer

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_toggle_team_tactics_ui_pressed():
	teamTacticsUICanvas.visible = !teamTacticsUICanvas.visible
	matchStatsUI.visible = false
	pass # Replace with function body.


func _on_toggle_stats_button_pressed() -> void:
	matchStatsUI.visible = !matchStatsUI.visible
	if matchStatsUI.visible:
		matchStatsUI.UpdateDisplay()
	teamTacticsUICanvas.visible = false

	pass # Replace with function body.
