extends CanvasLayer
class_name PreMatchUI

var newMatchData:NewMatchData
var gameWorld:GameWorld
var mManager:MatchManager

@onready var matchIntro = $ColourRectIntro
@onready var teamSelection = $TeamSelectionUI
@onready var teamLineups = $TeamLineUpsUI
@onready var toss = $Toss
@onready var wonToss = $Toss/WonToss
@onready var lostToss = $Toss/LostToss
@onready var matchStartMenu = $MatchStartMenu
@onready var fullStartMenu = $FullStartColourRect
@onready var athletesTableMenu = $AllAthletesTableColourRect
@onready var playerStatsTable:PlayerStatsTable = $AllAthletesTableColourRect/PlayerStatsTable
@onready var allAthletesTitleLabel:Label = $AllAthletesTableColourRect/AllAthletesTitleLabel

@onready var teamAChooser:TeamChoice = $FullStartColourRect/TeamAChooser
@onready var teamBChooser:TeamChoice = $FullStartColourRect/TeamBChooser

var usingAcceleratedStart:bool = false

func skipUI():
	matchIntro.hide()
	
func Init(_mManager:MatchManager):
	mManager = _mManager
	gameWorld = mManager.gameWorld
	newMatchData = mManager.newMatch
	newMatchData.aChoiceState = PlayerChoiceState.new(gameWorld)
	newMatchData.bChoiceState = PlayerChoiceState.new(gameWorld)
	teamAChooser.Init(self, gameWorld, newMatchData.aChoiceState)
	teamBChooser.Init(self, gameWorld, newMatchData.bChoiceState)
	

func _ready():
	matchStartMenu.show()
	fullStartMenu.hide()
	matchIntro.hide()
	
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



func _on_back_button_full_start_pressed():
	fullStartMenu.hide()
	matchStartMenu.show()


func _on_full_start_button_pressed():
	usingAcceleratedStart = false
	matchStartMenu.hide()
	fullStartMenu.show()


func _on_accelerated_start_button_pressed():
	usingAcceleratedStart = true
	newMatchData.ChooseRandom(gameWorld)
	allAthletesTitleLabel.text = mManager.teamA.teamName + " vs " + mManager.teamB.teamName
	athletesTableMenu.show()
	athletesTableMenu.get_node("PlayerStatsTable").PopulateTable(gameWorld.GetTeam(newMatchData.aChoiceState, newMatchData.clubOrInternational))
	pass # Replace with function body.


func _on_instant_start_button_pressed():
	hide()
	newMatchData.ChooseRandom(gameWorld)
	mManager.ConfirmTeams(gameWorld.GetTeam(newMatchData.aChoiceState, newMatchData.clubOrInternational), gameWorld.GetTeam(newMatchData.bChoiceState, newMatchData.clubOrInternational))
	mManager.StartGame()


func _on_full_start_confirm_button_pressed():
	if teamAChooser.ValidChoice() && teamBChooser.ValidChoice():
		fullStartMenu.hide()
		athletesTableMenu.show()
		
		allAthletesTitleLabel.text = mManager.teamA.teamName + " vs " + mManager.teamB.teamName
		athletesTableMenu.get_node("PlayerStatsTable").PopulateTable(gameWorld.GetTeam(newMatchData.aChoiceState, newMatchData.clubOrInternational))


func _on_back_button_table_pressed():
	playerStatsTable.clear()
	athletesTableMenu.hide()
	if usingAcceleratedStart:
		matchStartMenu.show()
	else:
		fullStartMenu.show()


func _on_table_confirm_button_pressed():
	if playerStatsTable.selectedPlayers.size() == 12:
		hide()
		mManager.StartGame()
	else:
		Console.AddNewLine("Number of selected players is not 12!")
		Console.AddNewLine("Number of selected players is not 12!")

func SyncroniseClubOrInternational(clubOrInternational:Enums.ClubOrInternational):
	# In the future, club vs international matches will be possible, but not yet
	# Also, matches with custom players drawn from anywhere
	
	if teamAChooser.clubOrInternationalMode == clubOrInternational:
		pass
	else:
		teamAChooser._on_club_or_international_left_button_pressed()
	
	if teamBChooser.clubOrInternationalMode == clubOrInternational:
		pass
	else:
		teamBChooser._on_club_or_international_left_button_pressed()
