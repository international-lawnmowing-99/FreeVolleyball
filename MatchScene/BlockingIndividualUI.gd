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
		
	if athlete.blockState.isCommitBlocking:
		$Background/ScrollContainer/MainContent/BlockType/BlockTypeOptionButton.select(0)
		var commitTargetIndex = otherTeam.courtPlayers.find(athlete.blockState.commitBlockTarget)
		$Background/ScrollContainer/MainContent/CommitBlockOptionsUI/CommitBlockTargetOptionButton.select(commitTargetIndex)
		$Background/ScrollContainer/MainContent/CommitBlockOptionsUI.show()
	else:
		$Background/ScrollContainer/MainContent/BlockType/BlockTypeOptionButton.select(1)
		$Background/ScrollContainer/MainContent/CommitBlockOptionsUI.hide()
	
	$Background/ScrollContainer/MainContent/ExcludeFromBlockCheckBox.set_pressed_no_signal(athlete.blockState.excludedFromBlock)
	$Background/ScrollContainer/MainContent/StartingPosition/StartingPositionHSlider.value = athlete.blockState.startingWidth
	
	
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
	athlete.blockState.startingWidth = value
	pass # Replace with function body.


func _on_exclude_from_block_check_box_toggled(button_pressed):
	athlete.blockState.excludedFromBlock = button_pressed

func _on_commitment_percent_h_slider_value_changed(value):
	var text
	if value <= 0:
		text = "Always commit to target"
	else:
		text = str("%.0f" % (value)) + "%"
	$Background/ScrollContainer/MainContent/CommitBlockOptionsUI/CommitmentPercentLabel.text = text
