extends Node

const dominoGenerator = preload("res://Scenes/domino.tscn")
const dottedGenerator = preload("res://Scenes/dotted.tscn")
var dominoVertical = true

func randomize_dots():
	$DominoGhost.putDots(randi_range(0, 6), randi_range(0, 6))

func _ready():
	randomize_dots()
	var newDominoPiece = dominoGenerator.instantiate()
	var viewportSize = get_viewport().size
	var center = viewportSize / 2
	newDominoPiece.position = $DominoGrid.getClosestCell(center.x, center.y, true)
	newDominoPiece.putDots($DominoGhost.dotsTop, $DominoGhost.dotsBot);
	$Dominoes.add_child(newDominoPiece)
	randomize_dots()

func _input(event):
	if event is InputEventMouseMotion:
		$DominoGhost.position = $DominoGrid.getClosestCell(event.position.x, event.position.y, dominoVertical)
		var closest = closestDomino(event.position)
	if event is InputEventMouseButton:
		if (event.button_index == 1 and event.button_mask > 0):
			var newDominoPiece = dominoGenerator.instantiate()
			newDominoPiece.position = $DominoGhost.position
			newDominoPiece.rotation = $DominoGhost.rotation
			newDominoPiece.putDots($DominoGhost.dotsTop, $DominoGhost.dotsBot);
			$Dominoes.add_child(newDominoPiece)
			randomize_dots()
		if (event.button_index == 2 and event.button_mask > 0):
			dominoVertical = !dominoVertical
			$DominoGhost.rotation += 0.5 * PI
	$DominoGhost.position = $DominoGrid.getClosestCell(event.position.x, event.position.y, dominoVertical)
			
func closestDomino(position: Vector2):
	var result = $Dominoes.get_children(true)[0]
	var dist = position.distance_to(result.position)
	for domino in $Dominoes.get_children(true):
		var dominoDist = position.distance_to(domino.position)
		if (dist > dominoDist):
			result = domino
			dist = dominoDist
	return result
