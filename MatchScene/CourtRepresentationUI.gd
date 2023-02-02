extends TextureRect

var courtPlayers

func AssignCourtPlayers(team:Team):
	courtPlayers = team.courtPlayers
	
func UpdateRepresentation():
	# mapping the players into 2d
	# the dimensions of the useable parts of the opposition's side of the court graphic are 428X428
	# however there's padding of 54 on the x dimension...
	
	# 0,0 is the centre of the court
	# the camera is in the positive x side and the negative z is to the right from that perspective
	for i in range(6):
		var rect = $OppositionTeam/UnscaledOppositionTeam.get_child(i)
		rect.rect_position.x = 428/-9 * courtPlayers[i].translation.z
		rect.rect_position.y = 428/9 * courtPlayers[i].translation.x
		
#		print("Mapping position to 2d, pos.x: " + courtPlayers[i].translation.x
