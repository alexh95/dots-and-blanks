extends Node

const dominoGenerator = preload("res://Scenes/domino.tscn")
const dottedGenerator = preload("res://Scenes/dotted.tscn")

var dominoVertical = true
var hoverGridPosition = Vector2i(0, 0)
var hoveredDomino = null

enum PlacingMode {NULL = 0, PLACE, REMOVE}
var mode: PlacingMode = PlacingMode.PLACE

func randomizeDots():
	$DominoContainer/DominoGhost.putDots(randi_range(0, 6), randi_range(0, 6))

func _ready():
	$UI/NameAndVersion.text = 'dots-and-blanks ' + ProjectSettings.get_setting('application/config/version')
	randomizeDots()
	var newDominoPiece = dominoGenerator.instantiate()
	hoverGridPosition = Vector2i(2, 2)
	calculateDominoGhostPosition(hoverGridPosition)
	newDominoPiece.vertical = dominoVertical
	newDominoPiece.gridPosition = hoverGridPosition
	newDominoPiece.position = $DominoContainer/DominoGhost.position
	newDominoPiece.putDots($DominoContainer/DominoGhost.dotsTop, $DominoContainer/DominoGhost.dotsBot);
	$DominoContainer/Dominoes.add_child(newDominoPiece)
	randomizeDots()
	$UI/RotateButton.pressed.connect(self.rotateDomino)
	$UI/CycleModeButton.pressed.connect(self.cycleMode)
	$UI/NextPieceButton.pressed.connect(self.nextDominoPiece)
	$UI/FullscreenButton.pressed.connect(self.toggleFullscreen)

func _input(event):
	if event is InputEventMouseMotion:
		resetDominoHighlight()
		calculateDominoGhostPositionFromScreen(event.position)
	if event is InputEventMouseButton:
		resetDominoHighlight()
		var canPerformAction = calculateDominoGhostPositionFromScreen(event.position)
		if (event.button_index == 1 and event.button_mask > 0):
			if canPerformAction:
				if mode == PlacingMode.PLACE:
					var newDominoPiece = dominoGenerator.instantiate()
					newDominoPiece.vertical = dominoVertical
					newDominoPiece.gridPosition = hoverGridPosition
					newDominoPiece.position = $DominoContainer/DominoGhost.position
					newDominoPiece.rotation = $DominoContainer/DominoGhost.rotation
					newDominoPiece.putDots($DominoContainer/DominoGhost.dotsTop, $DominoContainer/DominoGhost.dotsBot);
					$DominoContainer/Dominoes.add_child(newDominoPiece)
					randomizeDots()
				elif mode == PlacingMode.REMOVE:
					if hoveredDomino != null:
						$DominoContainer/Dominoes.remove_child(hoveredDomino)
		if (event.button_index == 2 and event.button_mask > 0):
			rotateDomino()
			calculateDominoGhostPositionFromScreen(event.position)
	
	if event is InputEventKey:
		if event.pressed && !event.echo:
			print(event)
		if event.keycode == 70 && event.pressed && !event.echo:
			toggleFullscreen()
		if event.keycode == 78 && event.pressed && !event.echo:
			randomizeDots()
		if event.keycode == 82 && event.pressed && !event.echo:
			rotateDomino()
		if event.keycode == 69 && event.pressed && !event.echo:
			cycleMode()

func setMode(newMode: PlacingMode):
	mode = newMode
	if newMode == PlacingMode.PLACE:
		$UI/PlacingMode.text = 'Mode: Placing'
		$DominoContainer/DominoGhost.visible = true
	else:
		$UI/PlacingMode.text = 'Mode: Removing'
		$DominoContainer/DominoGhost.visible = false

func closestDomino(position: Vector2):
	var result = $DominoContainer/Dominoes.get_children(true)[0]
	var dist = position.distance_to(result.position)
	for domino in $DominoContainer/Dominoes.get_children(true):
		var dominoDist = position.distance_to(domino.position)
		if (dist > dominoDist):
			result = domino
			dist = dominoDist
	return result
	
func searchDominoAt(screenPosition: Vector2i):
	var gridPosition = $DominoContainer/DominoGrid.getClosestGridPosition(screenPosition)
	for domino in $DominoContainer/Dominoes.get_children(true):
		var dominoSecondGridPosition = Vector2i(domino.gridPosition.x, domino.gridPosition.y + 1) if domino.vertical else Vector2i(domino.gridPosition.x + 1, domino.gridPosition.y)
		if domino.gridPosition == gridPosition or dominoSecondGridPosition == gridPosition:
			return domino
	return null
	
func calculateDominoGhostPositionFromScreen(screenPosition):
	hoverGridPosition = $DominoContainer/DominoGrid.getClosestGridPosition(screenPosition)
	calculateDominoGhostPosition(hoverGridPosition)	
	hoveredDomino = searchDominoAt(screenPosition)	
	if mode == PlacingMode.PLACE:
		$DominoContainer/DominoGhost.visible = true
		var isInGrid = $DominoContainer/DominoGrid.isInsideGrid(hoverGridPosition, dominoVertical)
		var isNotColliding = checkCollisions(hoverGridPosition, dominoVertical)
		var validGridPosition = isInGrid && isNotColliding
		if validGridPosition:
			$DominoContainer/DominoGhost.modulate = Color(0.0, 1.0, 0.0, 0.5)
		else:
			$DominoContainer/DominoGhost.modulate = Color(1.0, 0.0, 0.0, 0.5)
		return validGridPosition
	elif mode == PlacingMode.REMOVE:
		if hoveredDomino != null:
			highlightHoveredDominoForRemoval()
			return true
	return false
	
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
	
func resetDominoHighlight():
	for domino in $DominoContainer/Dominoes.get_children(true):
		domino.modulate = Color(1.0, 1.0, 1.0, 1.0)

func highlightHoveredDominoForRemoval():
	if hoveredDomino != null:
		hoveredDomino.modulate = Color(1.0, 0.0, 0.0, 1.0)
		
func cycleMode():
	resetDominoHighlight()
	if mode == PlacingMode.PLACE:
		setMode(PlacingMode.REMOVE)
		highlightHoveredDominoForRemoval()
	else:
		setMode(PlacingMode.PLACE)

func rotateDomino():
	dominoVertical = !dominoVertical
	$DominoContainer/DominoGhost.rotation += 0.5 * PI

func nextDominoPiece():
	randomizeDots()

func toggleFullscreen():
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
