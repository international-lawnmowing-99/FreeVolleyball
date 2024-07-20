extends Resource

class_name Continent

@export var continentName:String
@export var nations:Array[Nation] = []

func _init(nName = ""):
	continentName = nName
