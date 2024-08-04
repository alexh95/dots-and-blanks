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
	hoverGridPosition = Vector2i(2, 2)
	calculateDominoGhostPosition(hoverGridPosition)
	newDominoPiece.vertical = dominoVertical
	newDominoPiece.gridPosition = hoverGridPosition
	newDominoPiece.position = $DominoContainer/DominoGhost.position
	newDominoPiece.putDots($DominoContainer/DominoGhost.dotsTop, $DominoContainer/DominoGhost.dotsBot);
	$DominoContainer/Dominoes.add_child(newDominoPiece)
	randomize_dots()

func _input(event):
	if event is InputEventMouseMotion:
		calculateDominoGhostPositionFromScreen(event.position)
	if event is InputEventMouseButton:
		var canBePlaced = calculateDominoGhostPositionFromScreen(event.position)
		if (event.button_index == 1 and event.button_mask > 0):
			if canBePlaced:
				var newDominoPiece = dominoGenerator.instantiate()
				newDominoPiece.vertical = dominoVertical
				newDominoPiece.gridPosition = hoverGridPosition
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
		if event.keycode == 70 && event.pressed && !event.echo:
			if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			elif DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		if event.keycode == 82 && event.pressed && !event.echo:
			randomize_dots()
		if event.keycode == 77 && event.pressed && !event.echo:
			print('m')

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
	var isInGrid = $DominoContainer/DominoGrid.isInsideGrid(hoverGridPosition, dominoVertical)
	var isNotColliding = checkCollisions(hoverGridPosition, dominoVertical)
	var validGridPosition = isInGrid && isNotColliding
	if validGridPosition:
		$DominoContainer/DominoGhost.modulate = Color(0.0, 1.0, 0.0, 0.5)
	else:
		$DominoContainer/DominoGhost.modulate = Color(1.0, 0.0, 0.0, 0.5)
	calculateDominoGhostPosition(hoverGridPosition)
	return validGridPosition
	
func calculateDominoGhostPosition(gridPosition):
	var dominoScreenPosition = $DominoContainer/DominoGrid.getGridScreenPosition(gridPosition)
	if dominoVertical:
		dominoScreenPosition += $DominoContainer/DominoGrid.verticalCellOffset
	else:
		dominoScreenPosition += $DominoContainer/DominoGrid.horizontalCellOffset
	$DominoContainer/DominoGhost.position = dominoScreenPosition
	
func checkCollisions(gridPosition: Vector2i, vertical: bool):
	for domino in $DominoContainer/Dominoes.get_children(true):
		var dominoSecondGridPosition = Vector2i(domino.gridPosition.x, domino.gridPosition.y + 1) if domino.vertical else Vector2i(domino.gridPosition.x + 1, domino.gridPosition.y)
		var secondGridPosition = Vector2i(gridPosition.x, gridPosition.y + 1) if vertical else Vector2i(gridPosition.x + 1, gridPosition.y)
		if (domino.gridPosition == gridPosition) or (domino.gridPosition == secondGridPosition) or (dominoSecondGridPosition == gridPosition) or (dominoSecondGridPosition == secondGridPosition):
			return false
	return true
