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
var teamAWonToss:bool

func skipUI():
	hide()


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
	$TeamLineUpsUI/TeamAName.text = mManager.teamA.teamName
	$TeamLineUpsUI/TeamBName.text = mManager.teamB.teamName
	
	for i in range(12):
		$TeamLineUpsUI/HumanTeam.get_child(i).DisplayStats(mManager.teamA.matchPlayers[i])
		$TeamLineUpsUI/OppositionTeam.get_child(i).DisplayStats(mManager.teamB.matchPlayers[i])


func _Lineup_Button_pressed():
	teamLineups.hide()
	toss.show()


func TeamSelectionAcceptButton_pressed():
	if teamSelection.IsValid():
		teamSelection.hide()
		mManager.StartGame()
	else:
		Console.AddNewLine("Must choose a valid rotation")

func PopulateUI(team:Team, otherTeam:Team):
	$ColourRectIntro/Label.text = team.teamName + " vs " + otherTeam.teamName
	
	var humanTeam = $TeamLineUpsUI/HumanTeam
	if team.matchPlayers.size() > 12:
		Console.AddNewLine("Honey, we've duplicated the players somewhere...")
		return
	for i in range(team.matchPlayers.size()):
		if team.matchPlayers[i] && humanTeam.get_child(i):
			humanTeam.get_child(i).DisplayStats(team.matchPlayers[i])
			$TeamLineUpsUI/OppositionTeam.get_child(i).DisplayStats(otherTeam.matchPlayers[i])
	
	$TeamLineUpsUI/TeamAName.text = team.teamName
	$TeamLineUpsUI/TeamBName.text = otherTeam.teamName
	
	$TeamSelectionUI/TeamName.text = team.teamName
	
	for i in range(6):
		$TeamSelectionUI/HumanTeam.get_child(i).DisplayStats(team.matchPlayers[i])
		
	$TeamSelectionUI/LiberoNameCard.DisplayStats(team.matchPlayers[6])
	
	for i in range(5):
		$TeamSelectionUI/HumanTeamBench.get_child(i).DisplayStats(team.matchPlayers[7 + i])


func DoToss(choseHeads:bool):
	var coin:bool = randi() % 2
	print("coin is heads?: " + str(coin))
	if coin == true:
		$Toss/WonToss/CoinResultText.text = "Coin is Heads!"
		$Toss/LostToss/CoinResultText.text = "Coin is Heads!"
	else:
		$Toss/WonToss/CoinResultText.text = "Coin is Tails!"
		$Toss/LostToss/CoinResultText.text = "Coin is Tails!"
	
	if coin == choseHeads:
		wonToss.show()
		teamAWonToss = true
		
	else:
		lostToss.show()
		teamAWonToss = false
		
		if randi()%1 == 0:
			#Other team chose to serve/receive
			$Toss/LostToss/ChooseCurrentSide.show()
			$Toss/LostToss/ChooseOtherSide.show()
			if randi()%1 == 0:
				$Toss/LostToss/OppositionChoiceText.text = "Other team chose to serve"
				newMatchData.isTeamAServing = false
			else:
				$Toss/LostToss/OppositionChoiceText.text = "Other team chose to receive"
				newMatchData.isTeamAServing = true
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


func _on_ChooseHeads_pressed():
	DoToss(true)


func _on_ChooseServe_pressed():
	toss.hide()
	lostToss.hide()
	Console.AddNewLine("Choosing to serve")
	newMatchData.isTeamAServing = true
	
	if teamAWonToss:
		if randi_range(0, 1) == 1:
			Console.AddNewLine("Other team chose to stay on this side")
		else:
			Console.AddNewLine("Other team chose to change side")
			mManager.RotateTheBoard()
	
	teamSelection.show()

func _on_ChooseReceive_pressed():
	toss.hide()
	lostToss.hide()
	Console.AddNewLine("Choosing to receive")
	newMatchData.isTeamAServing = false
	
	if teamAWonToss:
		if randi_range(0, 1) == 1:
			Console.AddNewLine("Other team chose to stay on this side")
		else:
			Console.AddNewLine("Other team chose to change side")
			mManager.RotateTheBoard()
			
	teamSelection.show()

func _on_ChooseCurrentSide_pressed():
	toss.hide()
	lostToss.hide()
	Console.AddNewLine("Staying checked same side")
	teamSelection.show()

func _on_ChooseOtherSide_pressed():
	toss.hide()
	lostToss.hide()
	Console.AddNewLine("Changing sides like a dickhead")
	mManager.RotateTheBoard()
	teamSelection.show()

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
	allAthletesTitleLabel.text = gameWorld.GetTeam(newMatchData.aChoiceState, newMatchData.clubOrInternational).teamName + " vs " + gameWorld.GetTeam(newMatchData.bChoiceState, newMatchData.clubOrInternational).teamName
	athletesTableMenu.show()
	athletesTableMenu.get_node("PlayerStatsTable").PopulateTable(gameWorld.GetTeam(newMatchData.aChoiceState, newMatchData.clubOrInternational))



func _on_instant_start_button_pressed():
	hide()
	newMatchData.ChooseRandom(gameWorld)
	mManager.PrepareLocalTeamObjects(newMatchData)
	mManager.ConfirmTeams()
	mManager.StartGame()


func _on_full_start_confirm_button_pressed():
	if teamAChooser.ValidChoice() && teamBChooser.ValidChoice():
		SyncroniseClubOrInternational(teamAChooser.clubOrInternationalMode)
		fullStartMenu.hide()
		athletesTableMenu.show()
		mManager.PrepareLocalTeamObjects(newMatchData)

		allAthletesTitleLabel.text = mManager.teamA.teamName + " vs " + mManager.teamB.teamName

		athletesTableMenu.get_node("PlayerStatsTable").PopulateTable(mManager.teamA)


func _on_back_button_table_pressed():
	playerStatsTable.clear()
	athletesTableMenu.hide()
	if usingAcceleratedStart:
		matchStartMenu.show()
	else:
		fullStartMenu.show()


func _on_table_confirm_button_pressed():
	if playerStatsTable.selectedPlayers.size() == 12:
		if newMatchData.clubOrInternational == Enums.ClubOrInternational.International:
			for lad in playerStatsTable.matchPlayers:
				if lad.uiSelected:
					mManager.teamA.matchPlayers.append(lad)
			
			mManager.teamB.SelectNationalTeam()
		
		
		mManager.ConfirmTeams()
#		mManager.StartGame()
		matchStartMenu.hide()
		athletesTableMenu.hide()
		$ColourRectIntro/Label.text = mManager.teamA.teamName + " vs " + mManager.teamB.teamName
		matchIntro.show()
		
	else:
		Console.AddNewLine("Number of selected players is not 12!")

func SyncroniseClubOrInternational(clubOrInternational:Enums.ClubOrInternational):
	# In the future, club vs international matches will be possible, but not yet
	# Also, matches with custom players drawn from anywhere
	
	if teamAChooser.clubOrInternationalMode == Enums.ClubOrInternational.NotSelected:
		if clubOrInternational == Enums.ClubOrInternational.Club:
			teamAChooser._on_club_or_international_left_button_pressed()
		else:
			teamAChooser._on_club_or_international_right_button_pressed()
		return
	if teamBChooser.clubOrInternationalMode == Enums.ClubOrInternational.NotSelected:
		if clubOrInternational == Enums.ClubOrInternational.Club:
			teamBChooser._on_club_or_international_left_button_pressed()
		else:
			teamBChooser._on_club_or_international_right_button_pressed()
		return
		
	if teamAChooser.clubOrInternationalMode == clubOrInternational:
		pass
	else:
		teamAChooser._on_club_or_international_left_button_pressed()
	
	if teamBChooser.clubOrInternationalMode == clubOrInternational:
		pass
	else:
		teamBChooser._on_club_or_international_left_button_pressed()
	
	newMatchData.clubOrInternational = clubOrInternational

func _on_auto_select_pressed():
	playerStatsTable.selectedPlayers.clear()
	
	if newMatchData.clubOrInternational == Enums.ClubOrInternational.Club:
		for lad in playerStatsTable.matchPlayers:
			lad.uiSelected = true
			playerStatsTable.selectedPlayers.append(lad)
	elif newMatchData.clubOrInternational == Enums.ClubOrInternational.International:
		playerStatsTable.matchPlayers.sort_custom(Callable(Athlete,"SortSkill"))
		for i in range(12):
			playerStatsTable.matchPlayers[i].uiSelected = true
			playerStatsTable.selectedPlayers.append(playerStatsTable.matchPlayers[i])

	playerStatsTable._on_selected_pressed()
