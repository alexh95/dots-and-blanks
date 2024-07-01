extends Node

const dominoGenerator = preload("res://Scenes/domino.tscn")

func randomize_dots():
	$DominoGhost.putDots(randi_range(0, 6), randi_range(0, 6))

func _ready():
	randomize_dots()

func _input(event):
	if event is InputEventMouseMotion:
		$DominoGhost.position = event.position
	if event is InputEventMouseButton:
		if (event.button_index == 1 and event.button_mask > 0):
			var newDominoPiece = dominoGenerator.instantiate()
			newDominoPiece.position = event.position
			newDominoPiece.rotation = $DominoGhost.rotation
			newDominoPiece.putDots($DominoGhost.dotsTop, $DominoGhost.dotsBot);
			add_child(newDominoPiece)
			randomize_dots()
		if (event.button_index == 2 and event.button_mask > 0):
			$DominoGhost.rotation += 0.5 * PI
