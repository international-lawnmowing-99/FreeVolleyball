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
		if i < mManager.teamA.matchPlayers.size():
			(teamAParent.get_child(i) as NameCard).DisplayStats(mManager.teamA.matchPlayers[i])
			
			captainSelectPopup.add_item(mManager.teamA.matchPlayers[i].stats.lastName, i)
			libero1SelectPopup.add_item(mManager.teamA.matchPlayers[i].stats.lastName, i)
			libero2SelectPopup.add_item(mManager.teamA.matchPlayers[i].stats.lastName, i)
		
		else:
			teamAParent.get_child(i).hide()
		
	for i in 14:
		if i < mManager.teamB.matchPlayers.size():
			(teamBParent.get_child(i) as NameCard).DisplayStats(mManager.teamB.matchPlayers[i])
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
		mManager.teamA.libero.get_child(0).ChangeShirtColour()
	
	if mManager.teamA.libero2:
		mManager.teamA.libero2.get_child(0).ChangeShirtColour(Color( 1,0,4))

	if mManager.teamB.libero:
		mManager.teamB.libero.get_child(0).ChangeShirtColour()
	
	if mManager.teamB.libero2:
		mManager.teamB.libero2.get_child(0).ChangeShirtColour(Color(9,9,9))


func _on_CaptainSelect_popup_menu_id_pressed(id):
	mManager.teamA.teamCaptain = mManager.teamA.matchPlayers[id]
	captainLabel.text = "Captain: " + mManager.teamA.matchPlayers[id].stats.lastName

	RefreshCaptainAndLiberoIcons()

func _on_libero_1_select_popup_menu_id_pressed(id):
	if mManager.teamA.libero2 == mManager.teamA.matchPlayers[id]:
		Console.AddNewLine("ERROR: must select two different liberos")
		return
		
	mManager.teamA.libero = mManager.teamA.matchPlayers[id]
	libero1Label.text = "Libero 1: " + mManager.teamA.matchPlayers[id].stats.lastName
	
	RefreshCaptainAndLiberoIcons()



func _on_libero_2_select_popup_menu_id_pressed(id):
	if mManager.teamA.libero == mManager.teamA.matchPlayers[id]:
		Console.AddNewLine("ERROR: must select two different liberos")
		return
		
	mManager.teamA.libero2 = mManager.teamA.matchPlayers[id]
	libero2Label.text = "Libero 2: " + mManager.teamA.matchPlayers[id].stats.lastName
	
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
