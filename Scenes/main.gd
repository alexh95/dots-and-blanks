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
	$DominoContainer/DominoGhost.putDots(1, 1)
	self.hoverGridPosition = Vector2i(2, 2)
	calculate_domino_ghost_position(self.hoverGridPosition)
	create_domino(hoverGridPosition)
	randomizeDots()
	$UI/RotateButton.pressed.connect(self.rotateDomino)
	$UI/CycleModeButton.pressed.connect(self.cycleMode)
	$UI/NextPieceButton.pressed.connect(self.nextDominoPiece)
	$UI/FullscreenButton.pressed.connect(self.toggleFullscreen)
	$UI/ResetBoardButton.pressed.connect(self.reset_board)

func _input(event):
	if event is InputEventMouseMotion:
		var screen_position = Vector2i(event.position)
		reset_domino_highlight()
		if $DominoContainer/Deck.selected_domino == null:
			$DominoContainer/DominoGhost.visible = false;
			highlight_hovered_domino(Vector2i(screen_position))
		else:
			$DominoContainer/DominoGhost.visible = true;
			var grid_position = $DominoContainer/DominoGrid.get_closest_grid_position(screen_position)
			calculate_domino_ghost_position(grid_position)
			var valid = is_valid_placing_position(grid_position, dominoGridRotation)
			$DominoContainer/DominoGhost.modulate = Color(0.0, 1.0, 0.0, 0.5) if valid else Color(1.0, 0.0, 0.0, 0.5)
		var deck_domino = $DominoContainer/Deck.get_domino_at_position(screen_position)
		$DominoContainer/Deck.highlight_domino(deck_domino)
	if event is InputEventMouseButton:
		var screen_position = Vector2i(event.position)
		reset_domino_highlight()
		if (event.button_index == 1 and event.button_mask > 0):
			var deck_domino = $DominoContainer/Deck.get_domino_at_position(screen_position)
			if deck_domino != null:
				$DominoContainer/Deck.select_domino(deck_domino)
				$DominoContainer/DominoGhost.visible = true
				$DominoContainer/DominoGhost.putDots(deck_domino.dotsTop, deck_domino.dotsBot)
			else:
				var deck_selected_domino = $DominoContainer/Deck.selected_domino
				if deck_selected_domino == null:
					var hovered_domino = search_domino_at(screen_position)
					if hovered_domino != null:
						remove_domino(hovered_domino)
				else:
					var grid_position = $DominoContainer/DominoGrid.get_closest_grid_position(screen_position)
					calculate_domino_ghost_position(grid_position)
					var valid = is_valid_placing_position(grid_position, dominoGridRotation)
					if valid:
						$DominoContainer/Deck.remove_selected_domino()
						create_domino(grid_position)
		if (event.button_index == 2 and event.button_mask > 0):
			rotateDomino()
			calculate_domino_ghost_position_from_screen(screen_position)
	
	if event is InputEventKey:
		if event.pressed && !event.echo:
			print(event)
		if event.keycode == 70 && event.pressed && !event.echo:
			toggleFullscreen()
		if event.keycode == 78 && event.pressed && !event.echo:
			randomizeDots()
		if event.keycode == 82 && event.pressed && !event.echo:
			if event.ctrl_pressed:
				reset_board()
			else:
				rotateDomino()
		if event.keycode == 69 && event.pressed && !event.echo:
			cycleMode()
		calculate_domino_ghost_position(self.hoverGridPosition)

func setMode(newMode: PlacingMode):
	self.mode = newMode
	if newMode == PlacingMode.PLACE:
		$UI/PlacingMode.text = 'Mode: Placing'
		$DominoContainer/DominoGhost.visible = true
	else:
		$UI/PlacingMode.text = 'Mode: Removing'
		$DominoContainer/DominoGhost.visible = false

func search_domino_at(screen_position: Vector2i) -> Domino:
	var grid_position = $DominoContainer/DominoGrid.get_closest_grid_position(screen_position)
	for domino in $DominoContainer/Dominoes.get_children(true):
		if domino.gridPosition == grid_position or domino.get_secondary_grid_position() == grid_position:
			return domino
	return null

func highlight_hovered_domino(screen_position: Vector2i):
	var hovered_domino = search_domino_at(screen_position)
	if hovered_domino != null:
		hovered_domino.modulate = Color(1.0, 0.0, 0.0, 1.0)

func calculate_domino_ghost_position_from_screen(screen_position: Vector2i):
	hoverGridPosition = $DominoContainer/DominoGrid.get_closest_grid_position(screen_position)
	calculate_domino_ghost_position(hoverGridPosition)
	hoveredDomino = search_domino_at(screen_position)
	if $DominoContainer/Deck.selected_domino != null:
		$DominoContainer/DominoGhost.visible = true
		return is_valid_placing_position(hoverGridPosition, dominoGridRotation)
	else:
		if hoveredDomino != null:
			highlightHoveredDominoForRemoval()
			return true
	return false

func is_valid_placing_position(grid_position, rotation) -> bool:
	if !$DominoContainer/DominoGrid.isInBounds(grid_position): return false
	if !$DominoContainer/DominoGrid.isInBounds(get_secondary_grid_position(grid_position, rotation)): return false
	if !checkCollisions(grid_position, rotation): return false
	if !matchDotValues(grid_position, rotation): return false
	return true
	
func matchDotValues(gridPosition, gridRotation):
	var primaryValue = $DominoContainer/DominoGhost.getDotValue(self.dominoGridRotation <= 1)
	var secondaryValue = $DominoContainer/DominoGhost.getDotValue(self.dominoGridRotation > 1)
	var secondaryGridPosition = get_secondary_grid_position(gridPosition, gridRotation)
	
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

func calculate_domino_ghost_position(grid_position: Vector2i):
	var domino_screen_position = $DominoContainer/DominoGrid.get_grid_screen_position(grid_position)
	if dominoGridRotation % 2 == 0:
		domino_screen_position += $DominoContainer/DominoGrid.verticalCellOffset
	else:
		domino_screen_position += $DominoContainer/DominoGrid.horizontalCellOffset
	$DominoContainer/DominoGhost.position = domino_screen_position

func checkCollisions(gridPosition: Vector2i, gridRotation: int):
	for domino in $DominoContainer/Dominoes.get_children(true):
		var gp0 = gridPosition
		var gp1 = get_secondary_grid_position(gridPosition, gridRotation)
		var dgp0 = domino.gridPosition
		var dgp1 = domino.get_secondary_grid_position()
		if gp0 == dgp0 or gp0 == dgp1 or gp1 == dgp0 or gp1 == dgp1:
			return false
	return true

func get_secondary_grid_position(grid_position, grid_rotation) -> Vector2i:
	var offset = Vector2i.DOWN if grid_rotation % 2 == 0 else Vector2i.RIGHT
	return grid_position + offset

func reset_domino_highlight():
	for domino in $DominoContainer/Dominoes.get_children(true):
		domino.modulate = Color(1.0, 1.0, 1.0, 1.0)

func highlightHoveredDominoForRemoval():
	if self.hoveredDomino != null:
		self.hoveredDomino.modulate = Color(1.0, 0.0, 0.0, 1.0)

func cycleMode():
	reset_domino_highlight()
	if self.mode == PlacingMode.PLACE:
		setMode(PlacingMode.REMOVE)
		highlightHoveredDominoForRemoval()
	else:
		setMode(PlacingMode.PLACE)
		is_valid_placing_position(hoverGridPosition, dominoGridRotation)

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
		
func reset_board():
	for domino in $DominoContainer/Dominoes.get_children(true):
		remove_domino(domino)

func create_domino(grid_position: Vector2i):
	var domino = dominoGenerator.instantiate()
	domino.gridPosition = grid_position
	domino.gridRotation = self.dominoGridRotation
	domino.position = $DominoContainer/DominoGhost.position
	domino.rotation = $DominoContainer/DominoGhost.rotation
	domino.putDots($DominoContainer/DominoGhost.dotsTop, $DominoContainer/DominoGhost.dotsBot);
	$DominoContainer/DominoGrid.update_dot_values(domino)
	$DominoContainer/Dominoes.add_child(domino)

func remove_domino(domino: Domino):
	if domino != null:
		$DominoContainer/DominoGrid.remove_dot_values(domino)
		$DominoContainer/Dominoes.remove_child(domino)
		$DominoContainer/Deck.add_domino(Vector2i(domino.dotsTop, domino.dotsBot))
