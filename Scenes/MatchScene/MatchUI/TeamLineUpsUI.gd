extends ColorRect
class_name TeamLineupsUI

var nameCards:Array
var mManager:MatchManager

@onready var teamAParent = $HumanTeam
@onready var teamBParent = $OppositionTeam

@onready var captainSelectPopup:PopupMenu = $CaptainLabel/CaptainSelectPopupMenu
@onready var libero1SelectPopup:PopupMenu = $Libero1Label/Libero1SelectPopupMenu
@onready var libero2SelectPopup:PopupMenu = $Libero2Label/Libero2SelectPopupMenu

@onready var captainLabel:Label = $CaptainLabel
@onready var libero1Label:Label = $Libero1Label
@onready var libero2Label:Label = $Libero2Label

@onready var noLiberoWarning:AcceptDialog = $Libero1Label/NoLiberoWarning

func _ready() -> void:
	noLiberoWarning.add_cancel_button("Cancel")
	for card in $OppositionTeam.get_children():
		nameCards.append(card)
	for card in $HumanTeam.get_children():
		nameCards.append(card)

	for card:NameCard in nameCards:
		card.DisplayEssentials()

func DisplayTeams():
	if !mManager.teamA:
		Console.AddNewLine("ERROR: No teamA in match manager")
		return

	if mManager.newMatch.clubOrInternational == Enums.ClubOrInternational.Club:
		$Libero2Label.hide()

	for i in 14:
		if i < mManager.teamA.matchPlayerNodes.size():
			(teamAParent.get_child(i) as NameCard).DisplayStats(mManager.teamA.matchPlayerNodes[i])

			captainSelectPopup.add_item(mManager.teamA.matchPlayerNodes[i].stats.lastName, i)
			libero1SelectPopup.add_item(mManager.teamA.matchPlayerNodes[i].stats.lastName, i)
			libero2SelectPopup.add_item(mManager.teamA.matchPlayerNodes[i].stats.lastName, i)

		else:
			teamAParent.get_child(i).hide()

	for i in 14:
		if i < mManager.teamB.matchPlayerNodes.size():
			(teamBParent.get_child(i) as NameCard).DisplayStats(mManager.teamB.matchPlayerNodes[i])
		else:
			teamBParent.get_child(i).hide()

	if mManager.teamA.teamCaptain:
		captainLabel.text = "Captain: " + mManager.teamA.teamCaptain.stats.lastName
	if mManager.teamA.libero:
		libero1Label.text = "Libero 1: " + mManager.teamA.libero.stats.lastName
	if mManager.teamA.libero2:
		libero2Label.text = "Libero 2: " + mManager.teamA.libero2.stats.lastName

	RefreshCaptainAndLiberoIcons()

func _on_select_captain_button_pressed():
	if !mManager.teamA:
		Console.AddNewLine("ERROR: No teamA in match manager")
		return

	captainSelectPopup.show()
	libero1SelectPopup.hide()
	libero2SelectPopup.hide()


func RefreshCaptainAndLiberoIcons():
	for card:NameCard in nameCards:
		if card.cardAthlete:
			card.DisplayStats(card.cardAthlete)
		if card.cardAthlete == mManager.teamA.teamCaptain || card.cardAthlete == mManager.teamB.teamCaptain:
			card.captainIcon.show()
		else:
			card.captainIcon.hide()

		if card.cardAthlete == mManager.teamA.libero || card.cardAthlete == mManager.teamA.libero2\
		|| card.cardAthlete == mManager.teamB.libero || card.cardAthlete == mManager.teamB.libero2:
			card.liberoIcon.show()
		else:
			card.liberoIcon.hide()

	if mManager.teamA.libero:
		mManager.teamA.libero.model.ChangeShirtColour()

	if mManager.teamA.libero2:
		mManager.teamA.libero2.model.ChangeShirtColour(Color(4,0,0))

	if mManager.teamB.libero:
		mManager.teamB.libero.model.ChangeShirtColour()

	if mManager.teamB.libero2:
		mManager.teamB.libero2.model.ChangeShirtColour(Color(0,0,9))


func _on_CaptainSelect_popup_menu_id_pressed(id):
	mManager.teamA.teamCaptain = mManager.teamA.matchPlayerNodes[id]
	captainLabel.text = "Captain: " + mManager.teamA.matchPlayerNodes[id].stats.lastName

	RefreshCaptainAndLiberoIcons()

func _on_libero_1_select_popup_menu_id_pressed(id):
	if mManager.teamA.libero2 == mManager.teamA.matchPlayerNodes[id]:
		Console.AddNewLine("ERROR: must select two different liberos")
		return

	var previousLibero:Athlete
	var newLibero:Athlete = mManager.teamA.matchPlayerNodes[id]

	if mManager.teamA.libero:
		previousLibero = mManager.teamA.libero
		previousLibero.model.RevertShirtColour()
		previousLibero.stats.role = newLibero.stats.role


	mManager.teamA.libero = newLibero
	newLibero.stats.role = Enums.Role.Libero
	libero1Label.text = "Libero 1: " + newLibero.stats.lastName

	if previousLibero:
		mManager.teamA.InstantaneouslySwapPlayers(newLibero, previousLibero)
	elif newLibero in mManager.teamA.courtPlayerNodes:
		mManager.teamA.InstantaneouslySwapPlayers(newLibero, previousLibero)


	for i in range(mManager.teamA.playerToBeLiberoedOnServe.size()):
		if mManager.teamA.playerToBeLiberoedOnServe[i][2] == null || \
		mManager.teamA.playerToBeLiberoedOnServe[i][2] == previousLibero:
			mManager.teamA.playerToBeLiberoedOnServe[i][2] = newLibero


		if mManager.teamA.playerToBeLiberoedOnReceive[i][2] == null || \
		mManager.teamA.playerToBeLiberoedOnReceive[i][2] == previousLibero:
			mManager.teamA.playerToBeLiberoedOnReceive[i][2] = newLibero

		if mManager.teamA.playerToBeLiberoedOnServe[i][1] == newLibero:
			mManager.teamA.playerToBeLiberoedOnServe[i][1] = previousLibero

		if mManager.teamA.playerToBeLiberoedOnReceive[i][1] == newLibero:
			mManager.teamA.playerToBeLiberoedOnReceive[i][1] = previousLibero

	mManager.teamA.CachePlayers()
	RefreshCaptainAndLiberoIcons()



func _on_libero_2_select_popup_menu_id_pressed(id):
	if mManager.teamA.libero == mManager.teamA.matchPlayerNodes[id]:
		Console.AddNewLine("ERROR: must select two different liberos")
		return

	var previousLibero2:Athlete
	var newLibero2:Athlete = mManager.teamA.matchPlayerNodes[id]

	if mManager.teamA.libero2:
		previousLibero2 = mManager.teamA.libero2
		previousLibero2.model.RevertShirtColour()
		previousLibero2.stats.role = newLibero2.stats.role


	mManager.teamA.libero2 = newLibero2
	newLibero2.stats.role = Enums.Role.Libero
	libero2Label.text = "Libero 2: " + newLibero2.stats.lastName

	if previousLibero2:
		mManager.teamA.InstantaneouslySwapPlayers(newLibero2, previousLibero2)
		# The current match creation process always makes a libero if there are enough players,
		# so the alternative of choosing a player who may already be on the court doesn't happen


	for i in range(mManager.teamA.playerToBeLiberoedOnServe.size()):
		if mManager.teamA.playerToBeLiberoedOnServe[i][2] == null || \
		mManager.teamA.playerToBeLiberoedOnServe[i][2] == previousLibero2:
			mManager.teamA.playerToBeLiberoedOnServe[i][2] = newLibero2


		if mManager.teamA.playerToBeLiberoedOnReceive[i][2] == null || \
		mManager.teamA.playerToBeLiberoedOnReceive[i][2] == previousLibero2:
			mManager.teamA.playerToBeLiberoedOnReceive[i][2] = newLibero2

		if mManager.teamA.playerToBeLiberoedOnServe[i][1] == newLibero2:
			mManager.teamA.playerToBeLiberoedOnServe[i][1] = previousLibero2

		if mManager.teamA.playerToBeLiberoedOnReceive[i][1] == newLibero2:
			mManager.teamA.playerToBeLiberoedOnReceive[i][1] = previousLibero2

	mManager.teamA.CachePlayers()

	RefreshCaptainAndLiberoIcons()



func _on_select_libero_1_button_pressed():
	libero1SelectPopup.show()
	captainSelectPopup.hide()
	libero2SelectPopup.hide()


func _on_select_libero_2_button_pressed():
	libero2SelectPopup.show()
	captainSelectPopup.hide()
	libero1SelectPopup.hide()


func _on_no_libero_warning_confirmed():
	mManager.preMatchUI.TeamLineupsConfirmed()
