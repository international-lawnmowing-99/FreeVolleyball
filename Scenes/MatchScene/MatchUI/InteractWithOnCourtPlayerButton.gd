extends Button



func _on_InteractWithOnCourtPlayer_pressed() -> void:
	$AthleteTacticsPickerUI.visible = !$AthleteTacticsPickerUI.visible
