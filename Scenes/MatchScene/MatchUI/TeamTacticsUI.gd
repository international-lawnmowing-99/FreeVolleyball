extends Control
class_name TeamTacticsUI

@onready var receiveOptionsUI = $ReceiveOptionsUI
@onready var serveOptionsUI = $ServeOptionsUI
@onready var setOptionsUI = $SetOptionsUI
@onready var blockOptionsUI = $BlockOptionsUI

var teamA:TeamNode
var teamB:TeamNode

func _on_ServeUIButton_pressed() -> void:
	ShowServeOptions()

func ShowServeOptions():
	receiveOptionsUI.visible = false
	serveOptionsUI.visible = true
	setOptionsUI.visible = false
	blockOptionsUI.visible = false

func ShowReceiveOptions():
	receiveOptionsUI.visible = true
	serveOptionsUI.visible = false
	setOptionsUI.visible = false
	blockOptionsUI.visible = false

	if $ReceiveOptionsUI/DisplayedRotationLabel.text == "":
		receiveOptionsUI._on_current_rotation_button_pressed()


func ShowSetOptions():
	receiveOptionsUI.visible = false
	serveOptionsUI.visible = false
	setOptionsUI.visible = true
	blockOptionsUI.visible = false

func ShowBlockOptions():
	receiveOptionsUI.visible = false
	serveOptionsUI.visible = false
	setOptionsUI.visible = false
	blockOptionsUI.visible = true
	blockOptionsUI.UpdateBlockers(teamA, teamB)

func _on_receive_ui_button_pressed():
	ShowReceiveOptions()


func _on_set_ui_button_pressed():
	ShowSetOptions()


func _on_block_ui_button_pressed():
	ShowBlockOptions()

func Init(_teamA, _teamB):
	teamA = _teamA
	teamB = _teamB

	blockOptionsUI.teamA = teamA
	blockOptionsUI.teamB = teamB

	receiveOptionsUI.teamA = teamA
	receiveOptionsUI.teamB = teamB
	receiveOptionsUI.Init()
