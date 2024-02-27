extends CanvasLayer
class_name PreMatchUI

var newMatchData:NewMatchData
var gameWorld:GameWorld
var mManager:MatchManager

@onready var matchIntro = $ColourRectIntro
@onready var teamSubstitutionUI:TeamSubstitutionUI = $TeamSubstitutionUI
@onready var teamLineups:TeamLineupsUI = $TeamLineUpsUI
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

	matchStartMenu.show()
	fullStartMenu.hide()
	matchIntro.hide()
	
	teamSubstitutionUI.hide()
	teamLineups.mManager = mManager
	teamLineups.hide()
	toss.hide()
	wonToss.hide()
	lostToss.hide()


func _ready():
	$TeamSubstitutionUI/AcceptButton.connect("pressed",Callable(self,"TeamSubstitutionAcceptButton_pressed"))


func _on_Intro_Button_pressed():
	matchIntro.hide()
	teamLineups.show()
	$TeamLineUpsUI/TeamAName.text = mManager.teamA.teamName
	$TeamLineUpsUI/TeamBName.text = mManager.teamB.teamName
	
	teamLineups.DisplayTeams()


func _on_TeamLineups_ContinueButton_pressed():
	if !mManager.teamA.teamCaptain:
		Console.AddNewLine("Must select team captain!", Color.RED)
	#elif !mManager.teamA.libero:
		#
	elif mManager.newMatch.clubOrInternational == Enums.ClubOrInternational.International && mManager.teamA.matchPlayers.size() > 12 && !mManager.teamA.libero2:
		Console.AddNewLine("Must select two liberos when more than 12 players selected in FIVB competitions", Color.RED)
	elif !mManager.teamA.libero:
		teamLineups.noLiberoWarning.show()
	else:
		TeamLineupsConfirmed()

func TeamLineupsConfirmed():
	teamLineups.hide()
	toss.show()
 
func TeamSubstitutionAcceptButton_pressed():
	if !mManager.teamA.teamCaptain:
		Console.AddNewLine("Must designate a captain!")
		return
		
	for namecard:NameCard in teamSubstitutionUI.nameCards:
		if mManager.teamA.teamCaptain != namecard.cardAthlete:
			namecard.get_node("CaptainButton").hide()
	teamSubstitutionUI.hide()
	mManager.StartGame()

#func PopulateUI(team:Team, otherTeam:Team):
	##$ColourRectIntro/Label.text = team.teamName + " vs " + otherTeam.teamName
	##
	##var humanTeam = $TeamLineUpsUI/HumanTeam
	##if team.matchPlayers.size() > 12:
		##Console.AddNewLine("Honey, we've duplicated the players somewhere...")
		##return
	##for i in range(team.matchPlayers.size()):
		##if team.matchPlayers[i] && humanTeam.get_child(i):
			##humanTeam.get_child(i).DisplayStats(team.matchPlayers[i])
			##$TeamLineUpsUI/OppositionTeam.get_child(i).DisplayStats(otherTeam.matchPlayers[i])
	#
	#$TeamLineUpsUI/TeamAName.text = team.teamName
	#$TeamLineUpsUI/TeamBName.text = otherTeam.teamName
	#
	#$TeamSubstitutionUI/TeamName.text = team.teamName
	#
	#for i in range(6):
		#$TeamSubstitutionUI/HumanTeam.get_child(i).DisplayStats(team.matchPlayers[i])
		#
	#$TeamSubstitutionUI/LiberoNameCard.DisplayStats(team.matchPlayers[6])
	#
	#for i in range(5):
		#$TeamSubstitutionUI/HumanTeamBench.get_child(i).DisplayStats(team.matchPlayers[7 + i])


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
		
		if randi()%2 == 0:
			#Other team chose to serve/receive
			$Toss/LostToss/ChooseCurrentSide.show()
			$Toss/LostToss/ChooseOtherSide.show()
			if randi()%2 == 0:
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

			if randi()%2 == 0:
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
	
	teamSubstitutionUI.show()
	teamSubstitutionUI.Refresh()

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
			
	teamSubstitutionUI.show()
	teamSubstitutionUI.Refresh()

func _on_ChooseCurrentSide_pressed():
	toss.hide()
	lostToss.hide()
	Console.AddNewLine("Staying on the same side")
	teamSubstitutionUI.show()
	mManager.teamA.CheckForLiberoChange()
	teamSubstitutionUI.Refresh()

func _on_ChooseOtherSide_pressed():
	toss.hide()
	lostToss.hide()
	Console.AddNewLine("Changing sides like a dickhead")
	mManager.RotateTheBoard()
	teamSubstitutionUI.show()
	mManager.teamA.CheckForLiberoChange()
	teamSubstitutionUI.Refresh()

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
	
	if newMatchData.clubOrInternational == Enums.ClubOrInternational.International:
		(mManager.teamA as NationalTeam).SelectNationalTeam()
		(mManager.teamB as NationalTeam).SelectNationalTeam()
	
	mManager.ConfirmTeams()
	mManager.teamA.teamCaptain = mManager.teamA.matchPlayers[randi()%mManager.teamA.matchPlayers.size()]
	mManager.teamB.teamCaptain = mManager.teamA.matchPlayers[randi()%mManager.teamB.matchPlayers.size()]
	#Console.AddNewLine("Team A captain is: " + mManager.teamA.teamCaptain.stats.lastName)
	#Console.AddNewLine("Team B captain is: " + mManager.teamB.teamCaptain.stats.lastName)
	
	mManager.StartGame()


func _on_full_start_confirm_button_pressed():
	if teamAChooser.ValidChoice() && teamBChooser.ValidChoice():
		SyncroniseClubOrInternational(teamAChooser.clubOrInternationalMode)
		
		newMatchData.aChoiceState = teamAChooser.choiceState
		newMatchData.bChoiceState = teamBChooser.choiceState
		newMatchData.clubOrInternational = teamAChooser.clubOrInternationalMode
		
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
	var maxPlayers = 12
	if newMatchData.clubOrInternational == Enums.ClubOrInternational.International:
		maxPlayers = 14
	
	if playerStatsTable.selectedPlayers.size() < 6:
		Console.AddNewLine("Number of selected players isn't even enough to fill the whole court up...")
		
	elif playerStatsTable.selectedPlayers.size() > maxPlayers:
		if newMatchData.clubOrInternational == Enums.ClubOrInternational.International:
			Console.AddNewLine("Number of selected players is not between 6 and 14!")
		else:
			Console.AddNewLine("Number of selected players is not between 6 and 12!")

	else:
		mManager.PrepareLocalTeamObjects(newMatchData)


		if newMatchData.clubOrInternational == Enums.ClubOrInternational.International:
			for lad in playerStatsTable.matchPlayers:
				if lad.uiSelected:
					mManager.teamA.matchPlayers.append(lad)
			mManager.teamB.SelectNationalTeam()
		else:
			mManager.teamA.matchPlayers.clear()
			for lad in playerStatsTable.matchPlayers:
				if lad.uiSelected:
					mManager.teamA.matchPlayers.append(lad)
		mManager.ConfirmTeams()
	#		mManager.StartGame()
		matchStartMenu.hide()
		athletesTableMenu.hide()
		$ColourRectIntro/Label.text = mManager.teamA.teamName + " vs " + mManager.teamB.teamName
		matchIntro.show()
	
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
	for athlete:Athlete in playerStatsTable.selectedPlayers:
		athlete.uiSelected = false
	playerStatsTable.selectedPlayers.clear()
	
	if newMatchData.clubOrInternational == Enums.ClubOrInternational.Club:
		for lad in playerStatsTable.matchPlayers:
			lad.uiSelected = true
			playerStatsTable.selectedPlayers.append(lad)
	elif newMatchData.clubOrInternational == Enums.ClubOrInternational.International:
		playerStatsTable.matchPlayers.sort_custom(Callable(Athlete,"SortSkill"))
		for i in range(14):
			playerStatsTable.matchPlayers[i].uiSelected = true
			playerStatsTable.selectedPlayers.append(playerStatsTable.matchPlayers[i])

	playerStatsTable._on_selected_pressed()
