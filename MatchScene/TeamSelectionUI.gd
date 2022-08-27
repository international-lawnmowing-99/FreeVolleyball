extends ColorRect

var nameCards:Array
var normalColour = Color.chocolate
var mManager:MatchManager
var athleteToBeSubbed

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
		card.teamSelectionUI = self

func CardSelected(athlete:Athlete):
	if $PlayerStatsViewer:
		$PlayerStatsViewer.Populate(athlete)

func RequestSub(athlete:Athlete):
	#Check who is allowed to sub...
	
	athleteToBeSubbed = athlete
	
	for card in nameCards:
		card.ChangeColour(Color.red)
	for card in $HumanTeamBench.get_children():
		card.state = Enums.NameCardState.Substitutable
		card.ChangeColour(Color.chartreuse)

func ExecuteSub(incoming:Athlete):
	
	incoming.team.InstantaneouslySwapPlayers(athleteToBeSubbed, incoming)
	Refresh(incoming.team)
	
	for card in $HumanTeamBench.get_children():
		card.state = Enums.NameCardState.UNDEFINED
	for card in nameCards:
		card.ChangeColour(normalColour)
	pass

func RotateClockwise(team:Team):
	#can only rotate before the serve
	team.Rotate()
	Refresh(team)
	team.stateMachine.SetCurrentState(team.preserviceState)
	pass
	
func RotateAntiClockwise(team:Team):
	for i in range(5):
		RotateClockwise(team)
		
func Refresh(team:Team = mManager.teamA):
	$TeamName.text = team.teamName
	
	if mManager.score.teamAScore == 0 && mManager.score.teamBScore == 0:
		EnableRotate()
	else:
		DisableRotate()
	
	var playerNotAppearingOnBench
	if team.isLiberoOnCourt:
		$LiberoNameCard.DisplayStats(team.middleBack)
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
