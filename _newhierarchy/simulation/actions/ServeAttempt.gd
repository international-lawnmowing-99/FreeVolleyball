extends Attempt
class_name ServeAttempt

func resolve() -> ServeOutcome:
	var outcome := ServeOutcome.new()

	var roll = rng.randf()
	outcome.actor = actor

	var error_threshold = 1 - actor.serve/100
	var ace_threshold = error_threshold + actor.serve/100/3
	print (str(roll) + " vs. " + str(error_threshold)+ " vs. " + str(ace_threshold))

	if roll < error_threshold:
		print("serve error")
		# Service error
		outcome.success = false
		outcome.service_error = true
		outcome.terminal = true
		outcome.point_winner = ctx.defender

	elif roll < ace_threshold:
		print("ace")
		# Ace
		outcome.success = true
		outcome.ace = true
		outcome.terminal = true
		outcome.point_winner = ctx.attacker

	else:
		print("ball in play")
		# Ball in play
		outcome.success = true
		outcome.terminal = false

	return outcome
