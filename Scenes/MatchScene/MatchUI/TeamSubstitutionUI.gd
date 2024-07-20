extends ColorRect
class_name TeamSubstitutionUI

var nameCards:Array
var normalColour = Color.CHOCOLATE
var mManager:MatchManager
var athleteToBeSubbed:Athlete
const MAXSUBSFIVB = 6

@onready var liberoOptionsPanel:LiberoOptionsPanel = $LiberoOptionsPanel

@onready var libero1NameCard:NameCard = $Libero1NameCard
@onready var libero2NameCard:NameCard = $Libero2NameCard

func _ready() -> void:
	mManager = get_tree().root.get_node("MatchScene")

	nameCards.append(libero1NameCard)
	nameCards.append(libero2NameCard)
	$Libero1NameCard/SubstituteButton.hide()
	$Libero2NameCard/SubstituteButton.hide()

	for card in $HumanTeamBench.get_children():
		nameCards.append(card)
		card.Benched()
	for card in $HumanTeam.get_children():
		nameCards.append(card)
	for card in nameCards:
		card.ChangeColour(normalColour)
		card.teamSubstitutionUI = self

func CardSelected(athlete:Athlete):
	if athlete && $PlayerStatsViewer:
		$PlayerStatsViewer.Populate(athlete)

func RequestSub(athlete:Athlete):
	#Check who is allowed to sub...
	if athlete.team.numberOfSubsUsed >= MAXSUBSFIVB:
		Console.AddNewLine("All substitutions used as per FIVB limit")
		return

	athleteToBeSubbed = athlete

	for card in nameCards:
		card.ChangeColour(Color.RED)
	for card:NameCard in $HumanTeamBench.get_children():
		if !card.cardAthlete:
			continue
		# Players can only reenter the court to their original rotation position
		if card.cardAthlete.substitutionInfo.startingRotationPosition != -1:
			if athleteToBeSubbed.substitutionInfo.startingRotationPosition != card.cardAthlete.substitutionInfo.startingRotationPosition:
				Console.AddNewLine(card.cardAthlete.stats.lastName + " not able to sub on as started on court in position " + str(card.cardAthlete.substitutionInfo.startingRotationPosition))

		elif !card.cardAthlete.substitutionInfo.hasEnteredCourtFromBenchThisSet:
			card.state = Enums.NameCardState.Substitutable
			card.ChangeColour(Color.CHARTREUSE)

func ExecuteSub(incoming:Athlete):
	if !mManager.preSet:
		incoming.substitutionInfo.hasEnteredCourtFromBenchThisSet = true
		incoming.substitutionInfo.startingRotationPosition = athleteToBeSubbed.substitutionInfo.startingRotationPosition
		incoming.team.numberOfSubsUsed += 1


	incoming.team.InstantaneouslySwapPlayers(athleteToBeSubbed, incoming)
	if mManager.preSet:
			athleteToBeSubbed.substitutionInfo.startingRotationPosition = -1
	Refresh(incoming.team)

	for card in $HumanTeamBench.get_children():
		card.state = Enums.NameCardState.UNDEFINED
	for card in nameCards:
		card.ChangeColour(normalColour)

	incoming.team.CachePlayers()


func RotateClockwise(team:TeamNode):
	#can only rotate before the serve
	team.Rotate()
	Refresh(team)
	team.stateMachine.SetCurrentState(team.preserviceState)
	Console.AddNewLine("-")
	Console.AddNewLine("rotated orig rot 1: " + team.originalRotation1Player.stats.lastName)
	Console.AddNewLine("Orig rot 1 in position " + str(team.originalRotation1Player.stats.rotationPosition))

func RotateAntiClockwise(team:TeamNode):
	for i in range(5):
		RotateClockwise(team)

func Refresh(team:TeamNode = mManager.teamA):

	$TeamName.text = team.data.teamName
	if !mManager.preSet:
		$SubsRemainingLabel.text = str(MAXSUBSFIVB - team.numberOfSubsUsed) + " Substitutes Remaining"

	if mManager.preSet:
		EnableRotate()
	else:
		DisableRotate()

	var playerNotAppearingOnBench
	if team.libero:
		libero1NameCard.DisplayStats(team.libero)
	else:
		libero1NameCard.hide()
	if team.libero2:
		libero2NameCard.DisplayStats(team.libero2)
	else:
		libero2NameCard.hide()


	if team.data.isLiberoOnCourt:
		if mManager.isTeamAServing:
			playerNotAppearingOnBench = team.playerToBeLiberoedOnServe[mManager.teamA.originalRotation1Player.stats.rotationPosition - 1][1]
		else:
			playerNotAppearingOnBench = team.playerToBeLiberoedOnReceive[mManager.teamA.originalRotation1Player.stats.rotationPosition - 1][1]
	else:
		playerNotAppearingOnBench = team.libero

	var i = 0
	for athlete in team.benchPlayerNodes:
		if athlete != playerNotAppearingOnBench:
			$HumanTeamBench.get_child(i).DisplayStats(athlete)
			i += 1
	for card:NameCard in $HumanTeamBench.get_children():
		if !card.cardAthlete:
			card.hide()
		if card.cardAthlete == team.libero2:
			card.hide()

	var displayAthlete
	for athlete in team.courtPlayerNodes:
		if athlete == team.libero || athlete == team.libero2:
			displayAthlete = playerNotAppearingOnBench
		else:
			displayAthlete = athlete
		match athlete.stats.rotationPosition:
			1: $HumanTeam/NameCard1.DisplayStats(displayAthlete)
			2: $HumanTeam/NameCard2.DisplayStats(displayAthlete)
			3: $HumanTeam/NameCard3.DisplayStats(displayAthlete)
			4: $HumanTeam/NameCard4.DisplayStats(displayAthlete)
			5: $HumanTeam/NameCard5.DisplayStats(displayAthlete)
			6: $HumanTeam/NameCard6.DisplayStats(displayAthlete)

	if team.teamCaptain:
		for nameCard:NameCard in nameCards:
			nameCard.get_node("CaptainButton").hide()
			#Console.AddNewLine(team.teamCaptain.stats.lastName, Color.REBECCA_PURPLE)
			#Console.AddNewLine(nameCard.cardAthlete.stats.lastName)
			if nameCard.cardAthlete == team.teamCaptain:

				nameCard.get_node("CaptainIcon").show()
			else:
				nameCard.get_node("CaptainIcon").hide()

	for nameCard:NameCard in nameCards:
		nameCard.get_node("LiberoIcon").hide()
		if playerNotAppearingOnBench != team.libero && playerNotAppearingOnBench != team.libero2:
			if nameCard.cardAthlete == playerNotAppearingOnBench:
				nameCard.get_node("LiberoIcon").show()


func EnableRotate():
	$RotationControl.show()

func DisableRotate():
	$RotationControl.hide()

func _on_AntiClockwiseButton_pressed() -> void:
	RotateAntiClockwise(mManager.teamA)

func _on_ClockwiseButton_pressed() -> void:
	RotateClockwise(mManager.teamA)


func _on_CancelSubButton_pressed() -> void:
	athleteToBeSubbed = null
	for card in $HumanTeamBench.get_children():
		card.state = Enums.NameCardState.UNDEFINED
	for card in nameCards:
		card.ChangeColour(normalColour)
	pass # Replace with function body.

func SelectCaptain(athlete:Athlete):
	athlete.team.teamCaptain = athlete
	for nameCard:NameCard in nameCards:
		if nameCard.cardAthlete != athlete:
			nameCard.get_node("CaptainIcon").visible = false
		else:
			nameCard.get_node("CaptainIcon").visible = true


func _on_libero_options_button_pressed():
	if liberoOptionsPanel.visible:
		liberoOptionsPanel.hide()
	else:
		liberoOptionsPanel.show()
		Console.Clear()
		liberoOptionsPanel.DisplayRotation(mManager.teamA.originalRotation1Player.stats.rotationPosition)
