extends Node

const dominoGenerator = preload("res://Scenes/domino.tscn")
const dottedGenerator = preload("res://Scenes/dotted.tscn")

var dominoGridRotation = 0
var hoverGridPosition = Vector2i(0, 0)
var hoveredDomino = null

enum PlacingMode {NULL = 0, PLACE, REMOVE}
var mode: PlacingMode = PlacingMode.PLACE

const directionOffsets = [
	Vector2i( 0, 1),
	Vector2i( 1, 0),
	Vector2i( 0,-1),
	Vector2i(-1, 0),
]

func randomizeDots():
	$DominoContainer/DominoGhost.putDots(randi_range(0, 6), randi_range(0, 6))

func _ready():
	$UI/NameAndVersion.text = 'dots-and-blanks ' + ProjectSettings.get_setting('application/config/version')
	randomizeDots()
	self.hoverGridPosition = Vector2i(2, 2)
	calculateDominoGhostPosition(self.hoverGridPosition)
	createDominoPiece()
	randomizeDots()
	$UI/RotateButton.pressed.connect(self.rotateDomino)
	$UI/CycleModeButton.pressed.connect(self.cycleMode)
	$UI/NextPieceButton.pressed.connect(self.nextDominoPiece)
	$UI/FullscreenButton.pressed.connect(self.toggleFullscreen)
	$UI/ResetBoardButton.pressed.connect(self.resetBoard)

func _input(event):
	if event is InputEventMouseMotion:
		resetDominoHighlight()
		calculateDominoGhostPositionFromScreen(event.position)
	if event is InputEventMouseButton:
		resetDominoHighlight()
		var canPerformAction = calculateDominoGhostPositionFromScreen(event.position)
		if (event.button_index == 1 and event.button_mask > 0):
			if canPerformAction:
				if self.mode == PlacingMode.PLACE:
					createDominoPiece()
					randomizeDots()
				elif self.mode == PlacingMode.REMOVE:
					removeDominoPiece(self.hoveredDomino)
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
			if event.ctrl_pressed:
				resetBoard()
			else:
				rotateDomino()
		if event.keycode == 69 && event.pressed && !event.echo:
			cycleMode()
		calculateDominoGhostPosition(self.hoverGridPosition)

func setMode(newMode: PlacingMode):
	self.mode = newMode
	if newMode == PlacingMode.PLACE:
		$UI/PlacingMode.text = 'Mode: Placing'
		$DominoContainer/DominoGhost.visible = true
	else:
		$UI/PlacingMode.text = 'Mode: Removing'
		$DominoContainer/DominoGhost.visible = false

func searchDominoAt(screenPosition: Vector2i):
	var gridPosition = $DominoContainer/DominoGrid.getClosestGridPosition(screenPosition)
	for domino in $DominoContainer/Dominoes.get_children(true):
		if domino.gridPosition == gridPosition or domino.getSecondaryGridPosition() == gridPosition:
			return domino
	return null

func calculateDominoGhostPositionFromScreen(screenPosition):
	hoverGridPosition = $DominoContainer/DominoGrid.getClosestGridPosition(screenPosition)
	calculateDominoGhostPosition(hoverGridPosition)
	hoveredDomino = searchDominoAt(screenPosition)
	if mode == PlacingMode.PLACE:
		$DominoContainer/DominoGhost.visible = true
		return isValidPlacingPosition()
	elif mode == PlacingMode.REMOVE:
		if hoveredDomino != null:
			highlightHoveredDominoForRemoval()
			return true
	return false

func isValidPlacingPosition():
	var isInGrid = $DominoContainer/DominoGrid.isInBounds(hoverGridPosition) and $DominoContainer/DominoGrid.isInBounds(getSecondaryGridPosition(hoverGridPosition, dominoGridRotation))
	var isNotColliding = checkCollisions(hoverGridPosition, dominoGridRotation)
	var matchesDotValues = matchDotValues(hoverGridPosition, dominoGridRotation)
	var validGridPosition = isInGrid && isNotColliding && matchesDotValues
	if validGridPosition:
		$DominoContainer/DominoGhost.modulate = Color(0.0, 1.0, 0.0, 0.5)
	else:
		$DominoContainer/DominoGhost.modulate = Color(1.0, 0.0, 0.0, 0.5)
	return validGridPosition
	
func matchDotValues(gridPosition, gridRotation):
	var primaryValue = $DominoContainer/DominoGhost.getDotValue(self.dominoGridRotation <= 1)
	var secondaryValue = $DominoContainer/DominoGhost.getDotValue(self.dominoGridRotation > 1)
	var secondaryGridPosition = getSecondaryGridPosition(gridPosition, gridRotation)
	
	var primaryMatch = matchDotLocalValues(gridPosition, primaryValue)
	var secondaryMatch = matchDotLocalValues(secondaryGridPosition, secondaryValue)
	return primaryMatch or secondaryMatch;

func matchDotLocalValues(gridPosition: Vector2i, dotValue: int):
	for offset in directionOffsets:
		var targetGridPosition = gridPosition + offset
		if ($DominoContainer/DominoGrid.isInBounds(targetGridPosition)):
			var targetDotValue = $DominoContainer/DominoGrid.dotValues[targetGridPosition.y][targetGridPosition.x];
			if dotValue == targetDotValue:
				return true
	return false

func getDotValueAtPosition(gridPosition):
	for domino in $DominoContainer/Dominoes.get_children(true):
		var dominoSideHit = domino.getDominoSideAtPosition(gridPosition)
		if dominoSideHit > DominoSide.NULL:
			return domino.getDotValueAtSide(dominoSideHit)
	return -1

func calculateDominoGhostPosition(gridPosition):
	var dominoScreenPosition = $DominoContainer/DominoGrid.getGridScreenPosition(gridPosition)
	if dominoGridRotation % 2 == 0:
		dominoScreenPosition += $DominoContainer/DominoGrid.verticalCellOffset
	else:
		dominoScreenPosition += $DominoContainer/DominoGrid.horizontalCellOffset
	$DominoContainer/DominoGhost.position = dominoScreenPosition

func checkCollisions(gridPosition: Vector2i, gridRotation: int):
	for domino in $DominoContainer/Dominoes.get_children(true):
		var gp0 = gridPosition
		var gp1 = getSecondaryGridPosition(gridPosition, gridRotation)
		var dgp0 = domino.gridPosition
		var dgp1 = domino.getSecondaryGridPosition()
		if gp0 == dgp0 or gp0 == dgp1 or gp1 == dgp0 or gp1 == dgp1:
			return false
	return true

func getSecondaryGridPosition(gridPosition, gridRotation):
	var offset = Vector2i(0, 1) if gridRotation % 2 == 0 else Vector2i(1, 0)
	return gridPosition + offset

func resetDominoHighlight():
	for domino in $DominoContainer/Dominoes.get_children(true):
		domino.modulate = Color(1.0, 1.0, 1.0, 1.0)

func highlightHoveredDominoForRemoval():
	if self.hoveredDomino != null:
		self.hoveredDomino.modulate = Color(1.0, 0.0, 0.0, 1.0)

func cycleMode():
	resetDominoHighlight()
	if self.mode == PlacingMode.PLACE:
		setMode(PlacingMode.REMOVE)
		highlightHoveredDominoForRemoval()
	else:
		setMode(PlacingMode.PLACE)
		isValidPlacingPosition()

func rotateDomino():
	self.dominoGridRotation = (self.dominoGridRotation + 1) % 4
	$DominoContainer/DominoGhost.rotation = -0.5 * PI * self.dominoGridRotation

func nextDominoPiece():
	randomizeDots()

func toggleFullscreen():
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		
func resetBoard():
	for domino in $DominoContainer/Dominoes.get_children(true):
		removeDominoPiece(domino)

func createDominoPiece():
	var newDominoPiece = dominoGenerator.instantiate()
	newDominoPiece.gridPosition = self.hoverGridPosition
	newDominoPiece.gridRotation = self.dominoGridRotation
	newDominoPiece.position = $DominoContainer/DominoGhost.position
	newDominoPiece.rotation = $DominoContainer/DominoGhost.rotation
	newDominoPiece.putDots($DominoContainer/DominoGhost.dotsTop, $DominoContainer/DominoGhost.dotsBot);
	$DominoContainer/DominoGrid.updateDotValues(newDominoPiece)
	$DominoContainer/Dominoes.add_child(newDominoPiece)

func removeDominoPiece(dominoPiece):
	if dominoPiece != null:
		$DominoContainer/DominoGrid.removeDotValues(dominoPiece)
		$DominoContainer/Dominoes.remove_child(dominoPiece)
