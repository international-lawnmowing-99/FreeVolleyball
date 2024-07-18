extends ColorRect
class_name DodgyTossUI

@onready var wonToss = $WonToss
@onready var lostToss = $LostToss

@onready var wonTossCoinResultText: Label = $WonToss/CoinResultText
@onready var lostTossCoinResultText: Label = $LostToss/CoinResultText


var newMatchData:NewMatchData
var mManager:MatchManager

var isFifthSetToss:bool
var teamAWonToss:bool

func Init(_isFifthSetToss:bool, _mManager:MatchManager):
	isFifthSetToss = _isFifthSetToss
	mManager = _mManager
	newMatchData = mManager.newMatch

	wonToss.hide()
	lostToss.hide()


func DoToss(choseHeads:bool):
	var coin:bool = randi() % 2
	print("coin is heads?: " + str(coin))
	if coin == true:
		wonTossCoinResultText.text = "Coin is Heads!"
		lostTossCoinResultText.text = "Coin is Heads!"
	else:
		wonTossCoinResultText.text = "Coin is Tails!"
		lostTossCoinResultText.text = "Coin is Tails!"

	if coin == choseHeads:
		wonToss.show()
		lostToss.hide()
		teamAWonToss = true

	else:
		lostToss.show()
		wonToss.hide()
		teamAWonToss = false

		if randi()%2 == 0:
			#Other team chose to serve/receive
			$LostToss/ChooseCurrentSide.show()
			$LostToss/ChooseOtherSide.show()
			if randi()%2 == 0:
				$LostToss/OppositionChoiceText.text = "Other team chose to serve"
				Console.AddNewLine("Other team chose to serve")
				if isFifthSetToss:
					mManager.isTeamAServing = false
				else:
					newMatchData.isTeamAServing = false
			else:
				$LostToss/OppositionChoiceText.text = "Other team chose to receive"
				Console.AddNewLine("Other team chose to receive")
				if isFifthSetToss:
					mManager.isTeamAServing = true
				else:
					newMatchData.isTeamAServing = true
			pass
		else:
			#Other team chose side of court
			$LostToss/ChooseServe.show()
			$LostToss/ChooseReceive.show()
			$LostToss/ChooseCurrentSide.hide()
			$LostToss/ChooseOtherSide.hide()

			if randi()%2 == 0:
				$LostToss/OppositionChoiceText.text = "Other team chose to change sides of the court"
			else:
				$LostToss/OppositionChoiceText.text = "Other team chose to keep their side of the court"


func _on_ChooseTails_pressed():
	DoToss(false)


func _on_ChooseHeads_pressed():
	DoToss(true)


func _on_ChooseServe_pressed():
	hide()
	lostToss.hide()
	Console.AddNewLine("Choosing to serve")
	if isFifthSetToss:
		mManager.isTeamAServing = true
	else:
		newMatchData.isTeamAServing = true

	if teamAWonToss:
		if randi_range(0, 1) == 1:
			Console.AddNewLine("Other team chose to stay on this side")
		else:
			Console.AddNewLine("Other team chose to change side")
			mManager.RotateTheBoard()

	mManager.teamSubstitutionUI.show()
	mManager.teamA.CheckForLiberoChange()
	mManager.teamSubstitutionUI.Refresh()
	mManager.preMatchUI.hide()

func _on_ChooseReceive_pressed():
	hide()
	lostToss.hide()
	Console.AddNewLine("Choosing to receive")
	if isFifthSetToss:
		mManager.isTeamAServing = false
	else:
		newMatchData.isTeamAServing = false

	if teamAWonToss:
		if randi_range(0, 1) == 1:
			Console.AddNewLine("Other team chose to stay on this side")
		else:
			Console.AddNewLine("Other team chose to change side")
			mManager.RotateTheBoard()

	mManager.teamSubstitutionUI.show()
	mManager.teamA.CheckForLiberoChange()
	mManager.teamSubstitutionUI.Refresh()
	mManager.preMatchUI.hide()

func _on_ChooseCurrentSide_pressed():
	hide()
	lostToss.hide()
	Console.AddNewLine("Staying on the same side")
	mManager.teamSubstitutionUI.show()
	mManager.teamA.CheckForLiberoChange()
	mManager.teamSubstitutionUI.Refresh()
	mManager.preMatchUI.hide()

func _on_ChooseOtherSide_pressed():
	hide()
	lostToss.hide()
	Console.AddNewLine("Changing sides like a dickhead")
	mManager.RotateTheBoard()
	mManager.teamSubstitutionUI.show()
	mManager.teamA.CheckForLiberoChange()
	mManager.teamSubstitutionUI.Refresh()
	mManager.preMatchUI.hide()

func _on_ChooseSide_pressed():
	$WonToss/ChooseOtherSide.show()
	$WonToss/ChooseCurrentSide.show()

	$WonToss/ChooseSide.hide()
	$WonToss/ChooseServeReceive.hide()


func _on_ChooseServeReceive_pressed():
	$WonToss/ChooseReceive.show()
	$WonToss/ChooseServe.show()

	$WonToss/ChooseSide.hide()
	$WonToss/ChooseServeReceive.hide()
