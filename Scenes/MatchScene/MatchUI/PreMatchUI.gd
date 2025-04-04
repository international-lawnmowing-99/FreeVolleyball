extends CanvasLayer
class_name PreMatchUI

var newMatchData:NewMatchData
var gameWorld:GameWorld
var mManager:MatchManager

@onready var matchIntro = $ColourRectIntro
var teamSubstitutionUI:TeamSubstitutionUI
@onready var teamLineups:TeamLineupsUI = $TeamLineUpsUI
@onready var toss:DodgyTossUI = $TossUI
@onready var matchStartMenu = $MatchStartMenu
@onready var fullStartMenu = $FullStartColourRect
@onready var athletesTableMenu = $AllAthletesTableColourRect
@onready var playerStatsTable:PlayerStatsTable = $AllAthletesTableColourRect/PlayerStatsTable
@onready var allAthletesTitleLabel:Label = $AllAthletesTableColourRect/AllAthletesTitleLabel

@onready var teamAChooser:TeamChoice = $FullStartColourRect/TeamAChooser
@onready var teamBChooser:TeamChoice = $FullStartColourRect/TeamBChooser

var usingAcceleratedStart:bool = false


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

	teamSubstitutionUI = mManager.teamSubstitutionUI
	teamSubstitutionUI.get_node("AcceptButton").connect("pressed",Callable(self,"TeamSubstitutionAcceptButton_pressed"))
	matchStartMenu.show()
	fullStartMenu.hide()
	matchIntro.hide()

	teamSubstitutionUI.hide()
	teamLineups.mManager = mManager
	teamLineups.hide()

	toss.Init(false, mManager)
	toss.hide()


func _ready():
	pass


func _on_Intro_Button_pressed():
	matchIntro.hide()
	teamLineups.show()
	$TeamLineUpsUI/TeamAName.text = mManager.teamA.data.teamName
	$TeamLineUpsUI/TeamBName.text = mManager.teamB.data.teamName

	teamLineups.DisplayTeams()


func _on_TeamLineups_ContinueButton_pressed():
	if !mManager.teamA.teamCaptain:
		Console.AddNewLine("Must select team captain!", Color.RED)
	#elif !mManager.teamA.libero:
		#
	elif mManager.newMatch.clubOrInternational == Enums.ClubOrInternational.International && mManager.teamA.data.matchPlayers.size() > 12 && !mManager.teamA.libero2:
		Console.AddNewLine("Must select two liberos when more than 12 players selected in FIVB competitions", Color.RED)
	elif !mManager.teamA.libero:
		teamLineups.noLiberoWarning.show()
	else:
		TeamLineupsConfirmed()

func TeamLineupsConfirmed():
	teamLineups.hide()
	toss.show()

func TeamSubstitutionAcceptButton_pressed():
	if mManager.preMatch:
		if !mManager.teamA.teamCaptain:
			Console.AddNewLine("Must designate a captain!")
			return

		for namecard:NameCard in teamSubstitutionUI.nameCards:
			if mManager.teamA.teamCaptain != namecard.cardAthlete:
				namecard.get_node("CaptainButton").hide()
		teamSubstitutionUI.hide()


		mManager.StartMatch()






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
		(mManager.teamA.data as NationalTeam).SelectNationalTeam()
		(mManager.teamB.data as NationalTeam).SelectNationalTeam()

	mManager.ConfirmTeams()
	mManager.teamA.teamCaptain = mManager.teamA.matchPlayerNodes[randi()%mManager.teamA.matchPlayerNodes.size()]
	mManager.teamB.teamCaptain = mManager.teamB.matchPlayerNodes[randi()%mManager.teamB.matchPlayerNodes.size()]
	#Console.AddNewLine("Team A captain is: " + mManager.teamA.teamCaptain.stats.lastName)
	#Console.AddNewLine("Team B captain is: " + mManager.teamB.teamCaptain.stats.lastName)

	mManager.StartMatch()


func _on_full_start_confirm_button_pressed():
	if teamAChooser.ValidChoice() && teamBChooser.ValidChoice():
		SyncroniseClubOrInternational(teamAChooser.clubOrInternationalMode)

		newMatchData.aChoiceState = teamAChooser.choiceState
		newMatchData.bChoiceState = teamBChooser.choiceState
		newMatchData.clubOrInternational = teamAChooser.clubOrInternationalMode

		fullStartMenu.hide()
		athletesTableMenu.show()
		mManager.PrepareLocalTeamObjects(newMatchData)

		allAthletesTitleLabel.text = mManager.teamA.data.teamName + " vs " + mManager.teamB.data.teamName

		athletesTableMenu.get_node("PlayerStatsTable").PopulateTable(mManager.teamA.data)


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
					mManager.teamA.data.matchPlayers.append(lad)
			mManager.teamB.data.SelectNationalTeam()
		else:
			mManager.teamA.data.matchPlayers.clear()
			for lad in playerStatsTable.matchPlayers:
				if lad.uiSelected:
					mManager.teamA.data.matchPlayers.append(lad)
		mManager.ConfirmTeams()
	#		mManager.StartMatch()
		matchStartMenu.hide()
		athletesTableMenu.hide()
		$ColourRectIntro/Label.text = mManager.teamA.data.teamName + " vs " + mManager.teamB.data.teamName
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
	for athlete:AthleteStats in playerStatsTable.selectedPlayers:
		athlete.uiSelected = false
	playerStatsTable.selectedPlayers.clear()

	if newMatchData.clubOrInternational == Enums.ClubOrInternational.Club:
		for lad in playerStatsTable.matchPlayers:
			lad.uiSelected = true
			playerStatsTable.selectedPlayers.append(lad)
	elif newMatchData.clubOrInternational == Enums.ClubOrInternational.International:
		playerStatsTable.matchPlayers.sort_custom(Callable(AthleteStats,"SortSkill"))
		for i in range(14):
			playerStatsTable.matchPlayers[i].uiSelected = true
			playerStatsTable.selectedPlayers.append(playerStatsTable.matchPlayers[i])

	playerStatsTable._on_selected_pressed()
