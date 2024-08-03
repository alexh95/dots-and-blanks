extends Node

const dominoGenerator = preload("res://Scenes/domino.tscn")
const dottedGenerator = preload("res://Scenes/dotted.tscn")
var dominoVertical = true
var hoverGridPosition = Vector2i(0, 0)

func randomize_dots():
	$DominoContainer/DominoGhost.putDots(randi_range(0, 6), randi_range(0, 6))

func _ready():
	randomize_dots()
	var newDominoPiece = dominoGenerator.instantiate()
	calculateDominoGhostPosition(Vector2i(2, 2))
	newDominoPiece.position = $DominoContainer/DominoGhost.position
	newDominoPiece.putDots($DominoContainer/DominoGhost.dotsTop, $DominoContainer/DominoGhost.dotsBot);
	$DominoContainer/Dominoes.add_child(newDominoPiece)
	randomize_dots()

func _input(event):
	if event is InputEventMouseMotion:
		calculateDominoGhostPositionFromScreen(event.position)
	if event is InputEventMouseButton:
		calculateDominoGhostPositionFromScreen(event.position)
		if (event.button_index == 1 and event.button_mask > 0):
			var newDominoPiece = dominoGenerator.instantiate()
			newDominoPiece.position = $DominoContainer/DominoGhost.position
			newDominoPiece.rotation = $DominoContainer/DominoGhost.rotation
			newDominoPiece.putDots($DominoContainer/DominoGhost.dotsTop, $DominoContainer/DominoGhost.dotsBot);
			$DominoContainer/Dominoes.add_child(newDominoPiece)
			randomize_dots()
		if (event.button_index == 2 and event.button_mask > 0):
			dominoVertical = !dominoVertical
			$DominoContainer/DominoGhost.rotation += 0.5 * PI
			calculateDominoGhostPositionFromScreen(event.position)
			
	if event is InputEventKey:
		if event.pressed && !event.echo && event.keycode == 70:
			if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			elif DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func closestDomino(position: Vector2):
	var result = $DominoContainer/Dominoes.get_children(true)[0]
	var dist = position.distance_to(result.position)
	for domino in $DominoContainer/Dominoes.get_children(true):
		var dominoDist = position.distance_to(domino.position)
		if (dist > dominoDist):
			result = domino
			dist = dominoDist
	return result
	
func calculateDominoGhostPositionFromScreen(screenPosition):
	hoverGridPosition = $DominoContainer/DominoGrid.getClosestGridPosition(screenPosition)
	calculateDominoGhostPosition(hoverGridPosition)
	
func calculateDominoGhostPosition(gridPosition):
	var dominoScreenPosition = $DominoContainer/DominoGrid.getGridScreenPosition(gridPosition)
	if dominoVertical:
		dominoScreenPosition += $DominoContainer/DominoGrid.verticalCellOffset
	else:
		dominoScreenPosition += $DominoContainer/DominoGrid.horizontalCellOffset
	$DominoContainer/DominoGhost.position = dominoScreenPosition
