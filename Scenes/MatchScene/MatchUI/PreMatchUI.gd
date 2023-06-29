extends CanvasLayer

@onready var matchIntro = $ColourRectIntro
@onready var teamSelection = $TeamSelectionUI
@onready var teamLineups = $TeamLineUpsUI
@onready var toss = $Toss
@onready var wonToss = $Toss/WonToss
@onready var lostToss = $Toss/LostToss

func skipUI():
	matchIntro.hide()

func _ready():
	matchIntro.show()
	
	teamSelection.hide()
	teamLineups.hide()
	$TeamSelectionUI/AcceptButton.connect("pressed",Callable(self,"TeamSelectionAcceptButton_pressed"))
	toss.hide()
	wonToss.hide()
	lostToss.hide()
	
func _on_Intro_Button_pressed():
	matchIntro.hide()
	teamLineups.show()

func _Lineup_Button_pressed():
	teamLineups.hide()
	teamSelection.show()
	pass # Replace with function body.


func TeamSelectionAcceptButton_pressed():
	teamSelection.hide()
	toss.show()
# warning-ignore:return_value_discarded
	#get_tree().root.get_node("MatchScene")

func PopulateUI(team:Team, otherTeam:Team):
	$ColourRectIntro/Label.text = team.teamName + " vs " + otherTeam.teamName
	
	var humanTeam = $TeamLineUpsUI/HumanTeam
	if team.allPlayers.size() > 12:
		var teamDebug = team
	for i in range(team.allPlayers.size()):
		if team.allPlayers[i] && humanTeam.get_child(i):
			humanTeam.get_child(i).DisplayStats(team.allPlayers[i])
			$TeamLineUpsUI/OppositionTeam.get_child(i).DisplayStats(otherTeam.allPlayers[i])
	
	$TeamLineUpsUI/TeamAName.text = team.teamName
	$TeamLineUpsUI/TeamBName.text = otherTeam.teamName
	
	$TeamSelectionUI/TeamName.text = team.teamName
	
	for i in range(6):
		$TeamSelectionUI/HumanTeam.get_child(i).DisplayStats(team.allPlayers[i])
		
	$TeamSelectionUI/LiberoNameCard.DisplayStats(team.allPlayers[6])
	
	for i in range(5):
		$TeamSelectionUI/HumanTeamBench.get_child(i).DisplayStats(team.allPlayers[7 + i])

func DoToss(choseHeads:bool):
	var coin:bool = randi() % 1
	print("coin is heads?: " + str(coin))
	if coin == true:
		$Toss/WonToss/CoinResultText.text = "Coin is Heads!"
		$Toss/LostToss/CoinResultText.text = "Coin is Heads!"
	else:
		$Toss/WonToss/CoinResultText.text = "Coin is Tails!"
		$Toss/LostToss/CoinResultText.text = "Coin is Tails!"
	
	if coin == choseHeads:
		
		wonToss.show()
	else:
		
		lostToss.show()
		
		if randi()%1 == 0:
			#Other team chose to serve/receive
			$Toss/LostToss/ChooseCurrentSide.show()
			$Toss/LostToss/ChooseOtherSide.show()
			if randi()%1 == 0:
				$Toss/LostToss/OppositionChoiceText.text = "Other team chose to serve"
			else:
				$Toss/LostToss/OppositionChoiceText.text = "Other team chose to receive"
			pass
		else:
			#Other team chose side of court
			$Toss/LostToss/ChooseServe.show()
			$Toss/LostToss/ChooseReceive.show()

			if randi()%1 == 0:
				$Toss/LostToss/OppositionChoiceText.text = "Other team chose to change sides of the court"
			else:
				$Toss/LostToss/OppositionChoiceText.text = "Other team chose to keep their side of the court"
	
func _on_ChooseTails_pressed():
	DoToss(false)
	pass # Replace with function body.


func _on_ChooseHeads_pressed():
	DoToss(true)
	pass # Replace with function body.



func _on_ChooseServe_pressed():
	toss.hide()
	lostToss.hide()
	Console.AddNewLine("Choosing to serve")
	pass # Replace with function body.


func _on_ChooseReceive_pressed():
	toss.hide()
	lostToss.hide()
	Console.AddNewLine("Choosing to receive")
	pass # Replace with function body.


func _on_ChooseCurrentSide_pressed():
	toss.hide()
	lostToss.hide()
	Console.AddNewLine("Staying checked same side")
	pass # Replace with function body.


func _on_ChooseOtherSide_pressed():
	toss.hide()
	lostToss.hide()
	Console.AddNewLine("Changing sides like a dickhead")
	pass # Replace with function body.


func _on_ChooseSide_pressed():
	$Toss/WonToss/ChooseOtherSide.show()
	$Toss/WonToss/ChooseCurrentSide.show()
	
	$Toss/WonToss/ChooseSide.hide()
	$Toss/WonToss/ChooseServeReceive.hide()


func _on_ChooseServeReceive_pressed():
	$Toss/WonToss/ChooseReceive.show()
	$Toss/WonToss/ChooseServe.show()
	
	$Toss/WonToss/ChooseSide.hide()
	$Toss/WonToss/ChooseServeReceive.hide()

