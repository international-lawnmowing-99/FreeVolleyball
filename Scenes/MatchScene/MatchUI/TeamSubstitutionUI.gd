extends ColorRect
class_name TeamSubstitutionUI

var nameCards:Array
var normalColour = Color.CHOCOLATE
var mManager:MatchManager
var athleteToBeSubbed:Athlete
const MAXSUBSFIVB = 6

func _ready() -> void:
	mManager = get_tree().root.get_node("MatchScene")
	
	nameCards.append($LiberoNameCard)
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
	
	Refresh(incoming.team)
	
	for card in $HumanTeamBench.get_children():
		card.state = Enums.NameCardState.UNDEFINED
	for card in nameCards:
		card.ChangeColour(normalColour)
	
	incoming.team.CachePlayers()


func RotateClockwise(team:Team):
	#can only rotate before the serve
	team.Rotate()
	Refresh(team)
	team.stateMachine.SetCurrentState(team.preserviceState)
	Console.AddNewLine("-")
	Console.AddNewLine("rotated orig rot 1: " + team.originalRotation1Player.stats.lastName)
	Console.AddNewLine("Orig rot 1 in position " + str(team.originalRotation1Player.rotationPosition))
	
func RotateAntiClockwise(team:Team):
	for i in range(5):
		RotateClockwise(team)
		
func Refresh(team:Team = mManager.teamA):
	
	$TeamName.text = team.teamName
	if !mManager.preSet:
		$SubsRemainingLabel.text = str(MAXSUBSFIVB - team.numberOfSubsUsed) + " Substitutes Remaining"
	
	if mManager.preSet:
		EnableRotate()
	else:
		DisableRotate()
	
	var playerNotAppearingOnBench
	if team.isLiberoOnCourt:
		$LiberoNameCard.DisplayStats(team.libero)
		playerNotAppearingOnBench = team.middleBack
	else:
		$LiberoNameCard.DisplayStats(team.libero)
		playerNotAppearingOnBench = team.libero
	var i = 0
	for athlete in team.benchPlayers:
		if athlete != playerNotAppearingOnBench:
			$HumanTeamBench.get_child(i).DisplayStats(athlete)
			i += 1

	for athlete in team.courtPlayers:
		match athlete.rotationPosition:
			1: $HumanTeam/NameCard1.DisplayStats(athlete)
			2: $HumanTeam/NameCard2.DisplayStats(athlete)
			3: $HumanTeam/NameCard3.DisplayStats(athlete)
			4: $HumanTeam/NameCard4.DisplayStats(athlete)
			5: $HumanTeam/NameCard5.DisplayStats(athlete)
			6: $HumanTeam/NameCard6.DisplayStats(athlete)
	
	if team.teamCaptain:
		for nameCard:NameCard in nameCards:
			nameCard.get_node("CaptainButton").hide()
		
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
