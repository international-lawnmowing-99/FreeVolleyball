extends Control
class_name BlockingIndividualUI

var athlete:Athlete

func Populate(title:String, _athlete:Athlete, otherTeam:Team):
	if !_athlete || !otherTeam:
		Console.AddNewLine("!!! ERROR: blocker does not exist from UI's perspective !!!")
		return
	athlete = _athlete
	
	$Background/Title.text = title
	$Background/Name.text = athlete.stats.firstName + " " + athlete.stats.lastName
	$Background/ScrollContainer/MainContent/InfoLabels/Role.text = "Role: " + Enums.Role.keys()[athlete.role]
	
	$Background/ScrollContainer/MainContent/InfoLabels/RotationPosition.text = "Rotation Position: " + str(athlete.rotationPosition)
	$Background/ScrollContainer/MainContent/InfoLabels/BlockSkill.text = "Block: " + str("%.0f" %athlete.stats.block)
	$Background/ScrollContainer/MainContent/InfoLabels/BlockReach.text = "Block Reach: " + str(roundf(athlete.stats.blockHeight *100))+ "cm"
	$Background/ScrollContainer/MainContent/InfoLabels/Speed.text = "Speed: " + str("%.0f" %athlete.stats.speed)
	
	var i:int = 0
	$Background/ScrollContainer/MainContent/CommitBlockOptionsUI/CommitBlockTargetOptionButton.clear()
	$Background/ScrollContainer/MainContent/AnticipateAttacker/AnticipateAttackerOptionButton.clear()
	$Background/ScrollContainer/MainContent/AnticipateAttacker/AnticipateAttackerOptionButton.add_item("None")
	for oppositionPlayer in otherTeam.courtPlayers:
		$Background/ScrollContainer/MainContent/CommitBlockOptionsUI/CommitBlockTargetOptionButton.add_item(oppositionPlayer.stats.firstName + " " + oppositionPlayer.stats.lastName, i)
		$Background/ScrollContainer/MainContent/AnticipateAttacker/AnticipateAttackerOptionButton.add_item(oppositionPlayer.stats.firstName + " " + oppositionPlayer.stats.lastName, i + 1)
		i += 1


func _on_block_type_option_button_item_selected(index):
	# 0 is commit, 1 is react
	match index:
		0:
			$Background/ScrollContainer/MainContent/CommitBlockOptionsUI.show()
			athlete.blockState.isCommitBlocking = true
		1:
			$Background/ScrollContainer/MainContent/CommitBlockOptionsUI.hide()
			athlete.blockState.isCommitBlocking = false


func _on_starting_position_h_slider_value_changed(value):
	$Background/ScrollContainer/MainContent/StartingPosition/StartingPositionDistance.text = str(value)
	athlete.blockState.blockStrategy.startingWidth = value
	pass # Replace with function body.


func _on_exclude_from_block_check_box_toggled(button_pressed):
	athlete.blockState.blockStrategy.excludedFromBlock = button_pressed

