extends TextureRect

var courtPlayers

const xScaleGround = 0.2
const yScaleGround = 0.15

const xScaleAir = 0.3
const yScaleAir = 0.15*1.5

const lerpSpeed = 5

func AssignCourtPlayers(team:Team):
	courtPlayers = team.courtPlayers
	
func UpdateRepresentation(delta):
	# mapping the players into 2d
	# the dimensions of the useable parts of the opposition's side of the court graphic are 428X428
	# however there's padding of 54 checked the x dimension...
	
	# 0,0 is the centre of the court
	# the camera is in the positive x side and the negative z is to the right from that perspective
	for i in range(6):
		var rect = $OppositionTeam/UnscaledOppositionTeam.get_child(i)
		rect.position.x = 428/-9 * courtPlayers[i].position.z
		rect.position.y = 428/9 * courtPlayers[i].position.x
		
		if courtPlayers[i].rb.linear_velocity.y <= 0:
			rect.scale.x = lerp(rect.scale.x, xScaleGround, lerpSpeed*delta)
			rect.scale.y = lerp(rect.scale.y, yScaleGround, lerpSpeed*delta)
		else: 
			rect.scale.x = lerp(rect.scale.x, xScaleAir, lerpSpeed*delta)
			rect.scale.y = lerp(rect.scale.y, yScaleAir, lerpSpeed*delta)
#		print("Mapping position to 2d, pos.x: " + courtPlayers[i].position.x

#func DisplayRotation(team:Team, rot):
#
#	pass
