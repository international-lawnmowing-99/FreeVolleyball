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

func _ready() -> void:
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
	
	for i in mManager.teamA.matchPlayers.size():
		(teamAParent.get_child(i) as NameCard).DisplayStats(mManager.teamA.matchPlayers[i])
		
		captainSelectPopup.add_item(mManager.teamA.matchPlayers[i].stats.lastName, i)
		libero1SelectPopup.add_item(mManager.teamA.matchPlayers[i].stats.lastName, i)
		libero2SelectPopup.add_item(mManager.teamA.matchPlayers[i].stats.lastName, i)
		
		
	for i in mManager.teamB.matchPlayers.size():
		(teamBParent.get_child(i) as NameCard).DisplayStats(mManager.teamB.matchPlayers[i])


func _on_select_captain_button_pressed():
	if !mManager.teamA:
		Console.AddNewLine("ERROR: No teamA in match manager")
		return
		
	captainSelectPopup.show()
	libero1SelectPopup.hide()
	libero2SelectPopup.hide()

func _on_CaptainSelect_popup_menu_id_pressed(id):
	mManager.teamA.teamCaptain = mManager.teamA.matchPlayers[id]
	captainLabel.text = "Captain: " + mManager.teamA.matchPlayers[id].stats.lastName


func _on_libero_1_select_popup_menu_id_pressed(id):
	if mManager.teamA.libero2 == mManager.teamA.matchPlayers[id]:
		Console.AddNewLine("ERROR: must select two different liberos")
		return
		
	mManager.teamA.libero = mManager.teamA.matchPlayers[id]
	libero1Label.text = "Libero 1: " + mManager.teamA.matchPlayers[id].stats.lastName
	



func _on_libero_2_select_popup_menu_id_pressed(id):
	if mManager.teamA.libero == mManager.teamA.matchPlayers[id]:
		Console.AddNewLine("ERROR: must select two different liberos")
		return
		
	mManager.teamA.libero2 = mManager.teamA.matchPlayers[id]
	libero2Label.text = "Libero 2: " + mManager.teamA.matchPlayers[id].stats.lastName
	



func _on_select_libero_1_button_pressed():
	libero1SelectPopup.show()
	captainSelectPopup.hide()
	libero2SelectPopup.hide()


func _on_select_libero_2_button_pressed():
	libero2SelectPopup.show()
	captainSelectPopup.hide()
	libero1SelectPopup.hide()
