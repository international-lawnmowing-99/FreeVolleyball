extends Control


func Populate(athlete:Athlete, otherTeam:Team):
	
	$Background/Name.text = athlete.stats.firstName + " " + athlete.stats.lastName
	$Background/ScrollContainer/MainContent/InfoLabels/Role.text = "Role: " + Enums.Role.keys()[athlete.role]
	
	$Background/ScrollContainer/MainContent/InfoLabels/RotationPosition.text = "Rotation Position: " + str(athlete.rotationPosition)
	$Background/ScrollContainer/MainContent/InfoLabels/BlockSkill.text = "Block: " + str(athlete.stats.block)
	$Background/ScrollContainer/MainContent/InfoLabels/BlockReach.text = "Block Reach: " + str(athlete.stats.blockHeight)+ "cm"
	$Background/ScrollContainer/MainContent/InfoLabels/Speed.text = "Speed: " + str(athlete.stats.speed)
	
	var i:int = 0
	$Background/ScrollContainer/MainContent/CommitBlockOptionsUI/CommitBlockTargetOptionButton.clear()
	$Background/ScrollContainer/MainContent/AnticipateAttacker/AnticipateAttackerOptionButton.clear()
	for oppositionPlayer in otherTeam.courtPlayers:
		$Background/ScrollContainer/MainContent/CommitBlockOptionsUI/CommitBlockTargetOptionButton.add_item(oppositionPlayer.stats.firstName + " " + oppositionPlayer.stats.lastName, i)
		$Background/ScrollContainer/MainContent/AnticipateAttacker/AnticipateAttackerOptionButton.add_item(oppositionPlayer.stats.firstName + " " + oppositionPlayer.stats.lastName, i)
		i += 1


func _on_block_type_option_button_item_selected(index):
	# 0 is commit, 1 is react
	match index:
		0:
			$Background/ScrollContainer/MainContent/CommitBlockOptionsUI.show()
		1:
			$Background/ScrollContainer/MainContent/CommitBlockOptionsUI.hide()
