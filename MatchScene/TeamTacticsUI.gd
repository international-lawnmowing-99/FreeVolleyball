extends Control

@onready var receiveOptionsUI = $ReceiveOptionsUI
@onready var serveOptionsUI = $ServeOptionsUI
@onready var setOptionsUI = $SetOptionsUI
@onready var blockOptionsUI = $BlockOptionsUI

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


func _on_receive_ui_button_pressed():
	ShowReceiveOptions()


func _on_set_ui_button_pressed():
	ShowSetOptions()


func _on_block_ui_button_pressed():
	ShowBlockOptions()
