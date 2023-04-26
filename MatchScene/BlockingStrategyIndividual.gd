extends Node
class_name BlockingStrategyIndividual

var excludedFromBlock: bool = false

var primaryTarget:Athlete
var commitBlockPrimary: bool = false

# blocker has primary target before set 
# after set they react

func ReactToSet():
	if excludedFromBlock:
		# cover
		pass
	pass

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
