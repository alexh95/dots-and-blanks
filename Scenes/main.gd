extends Node

const domino_generator: PackedScene = preload("res://Scenes/domino.tscn")

var domino_grid_rotation: int = 0
var hover_grid_position = Vector2i(0, 0)
var hovered_domino = null

enum PlacingMode {NULL = 0, PLACE, REMOVE}
var mode: PlacingMode = PlacingMode.PLACE

const direction_offsets = [
	Vector2i( 0, 1),
	Vector2i( 1, 0),
	Vector2i( 0,-1),
	Vector2i(-1, 0),
]

func _ready() -> void:
	$UI/NameAndVersion.text = 'dots-and-blanks ' + ProjectSettings.get_setting('application/config/version')
	$DominoContainer/DominoGhost.put_dots(1, 1)
	self.hover_grid_position = Vector2i(2, 2)
	calculate_domino_ghost_position(self.hover_grid_position)
	create_domino(hover_grid_position)
	randomize_dots()
	$UI/RotateButton.pressed.connect(self.rotate_domino)
	$UI/CycleModeButton.pressed.connect(self.cycle_mode)
	$UI/NextPieceButton.pressed.connect(self.next_domino_piece)
	$UI/FullscreenButton.pressed.connect(self.toggle_fullscreen)
	$UI/ResetBoardButton.pressed.connect(self.reset_board)

func _input(event) -> void:
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
			var valid = is_valid_placing_position(grid_position, self.domino_grid_rotation)
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
				$DominoContainer/DominoGhost.put_dots(deck_domino.dots_top, deck_domino.dots_bot)
			else:
				var deck_selected_domino = $DominoContainer/Deck.selected_domino
				if deck_selected_domino == null:
					var hovered_domino = search_domino_at(screen_position)
					if hovered_domino != null:
						remove_domino(hovered_domino)
				else:
					var grid_position = $DominoContainer/DominoGrid.get_closest_grid_position(screen_position)
					calculate_domino_ghost_position(grid_position)
					var valid = is_valid_placing_position(grid_position, self.domino_grid_rotation)
					if valid:
						$DominoContainer/Deck.remove_selected_domino()
						create_domino(grid_position)
		if (event.button_index == 2 and event.button_mask > 0):
			rotate_domino()
			calculate_domino_ghost_position_from_screen(screen_position)
	if event is InputEventKey:
		if event.pressed && !event.echo:
			print(event)
		if event.keycode == 70 && event.pressed && !event.echo:
			toggle_fullscreen()
		if event.keycode == 78 && event.pressed && !event.echo:
			randomize_dots()
		if event.keycode == 82 && event.pressed && !event.echo:
			if event.ctrl_pressed:
				reset_board()
			else:
				rotate_domino()
		if event.keycode == 69 && event.pressed && !event.echo:
			cycle_mode()
		calculate_domino_ghost_position(self.hover_grid_position)

func set_mode(mode: PlacingMode) -> void:
	self.mode = mode
	if mode == PlacingMode.PLACE:
		$UI/PlacingMode.text = 'Mode: Placing'
		$DominoContainer/DominoGhost.visible = true
	else:
		$UI/PlacingMode.text = 'Mode: Removing'
		$DominoContainer/DominoGhost.visible = false

func search_domino_at(screen_position: Vector2i) -> Domino:
	var grid_position = $DominoContainer/DominoGrid.get_closest_grid_position(screen_position)
	for domino in $DominoContainer/Dominoes.get_children(true):
		if domino.grid_position == grid_position or domino.get_secondary_grid_position() == grid_position:
			return domino
	return null

func highlight_hovered_domino(screen_position: Vector2i) -> void:
	var hovered_domino = search_domino_at(screen_position)
	if hovered_domino != null:
		hovered_domino.modulate = Color(1.0, 0.0, 0.0, 1.0)

func calculate_domino_ghost_position_from_screen(screen_position: Vector2i) -> bool:
	hover_grid_position = $DominoContainer/DominoGrid.get_closest_grid_position(screen_position)
	calculate_domino_ghost_position(hover_grid_position)
	self.hovered_domino = search_domino_at(screen_position)
	if $DominoContainer/Deck.selected_domino != null:
		$DominoContainer/DominoGhost.visible = true
		return is_valid_placing_position(hover_grid_position, self.domino_grid_rotation)
	else:
		if hovered_domino != null:
			highlight_hovered_domino_for_removal()
			return true
	return false

func is_valid_placing_position(grid_position, rotation) -> bool:
	var primary_position_in_bounds = $DominoContainer/DominoGrid.is_in_bounds(grid_position)
	var secondary_position_in_bounds = $DominoContainer/DominoGrid.is_in_bounds(get_secondary_grid_position(grid_position, rotation))
	var no_collision = check_collisions(grid_position, rotation)
	var matches = match_dot_values(grid_position, rotation)
	return primary_position_in_bounds and secondary_position_in_bounds and no_collision and matches
	
func match_dot_values(grid_position, grid_rotation) -> bool:
	var primary_value = $DominoContainer/DominoGhost.get_dot_value(self.domino_grid_rotation <= 1)
	var secondary_value = $DominoContainer/DominoGhost.get_dot_value(self.domino_grid_rotation > 1)
	var secondary_grid_position = get_secondary_grid_position(grid_position, grid_rotation)
	var primary_match = match_dot_local_values(grid_position, primary_value)
	var secondary_match = match_dot_local_values(secondary_grid_position, secondary_value)
	return primary_match or secondary_match;

func match_dot_local_values(grid_position: Vector2i, dot_value: int) -> bool:
	for offset in direction_offsets:
		var target_grid_position = grid_position + offset
		if $DominoContainer/DominoGrid.is_in_bounds(target_grid_position):
			var target_dot_value = $DominoContainer/DominoGrid.dot_values[target_grid_position.y][target_grid_position.x];
			if dot_value == target_dot_value:
				return true
	return false

func get_dot_value_at_position(grid_position) -> int:
	for domino in $DominoContainer/Dominoes.get_children(true):
		var domino_side_hit = domino.get_domino_side_at_position(grid_position)
		if domino_side_hit > DominoSide.NULL:
			return domino.get_dot_value_at_side(domino_side_hit)
	return -1

func calculate_domino_ghost_position(grid_position: Vector2i) -> void:
	var domino_screen_position = $DominoContainer/DominoGrid.get_grid_screen_position(grid_position)
	if self.domino_grid_rotation % 2 == 0:
		domino_screen_position += $DominoContainer/DominoGrid.vertical_cell_offset
	else:
		domino_screen_position += $DominoContainer/DominoGrid.horizontal_cell_offset
	$DominoContainer/DominoGhost.position = domino_screen_position

func check_collisions(grid_position: Vector2i, grid_rotation: int) -> bool:
	for domino in $DominoContainer/Dominoes.get_children(true):
		var gp0 = grid_position
		var gp1 = get_secondary_grid_position(grid_position, grid_rotation)
		var dgp0 = domino.grid_position
		var dgp1 = domino.get_secondary_grid_position()
		if gp0 == dgp0 or gp0 == dgp1 or gp1 == dgp0 or gp1 == dgp1:
			return false
	return true

func get_secondary_grid_position(grid_position, grid_rotation) -> Vector2i:
	var offset = Vector2i.DOWN if grid_rotation % 2 == 0 else Vector2i.RIGHT
	return grid_position + offset

func reset_domino_highlight() -> void:
	for domino in $DominoContainer/Dominoes.get_children(true):
		domino.modulate = Color(1.0, 1.0, 1.0, 1.0)

func highlight_hovered_domino_for_removal() -> void:
	if self.hovered_domino != null:
		self.hovered_domino.modulate = Color(1.0, 0.0, 0.0, 1.0)

func cycle_mode() -> void:
	reset_domino_highlight()
	if self.mode == PlacingMode.PLACE:
		set_mode(PlacingMode.REMOVE)
		highlight_hovered_domino_for_removal()
	else:
		set_mode(PlacingMode.PLACE)
		is_valid_placing_position(hover_grid_position, self.domino_grid_rotation)

func rotate_domino() -> void:
	self.domino_grid_rotation = (self.domino_grid_rotation + 1) % 4
	$DominoContainer/DominoGhost.rotation = -0.5 * PI * self.domino_grid_rotation

func next_domino_piece() -> void:
	randomize_dots()

func randomize_dots() -> void:
	$DominoContainer/DominoGhost.put_dots(randi_range(0, 6), randi_range(0, 6))

func toggle_fullscreen() -> void:
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		
func reset_board() -> void:
	for domino in $DominoContainer/Dominoes.get_children(true):
		remove_domino(domino)

func create_domino(grid_position: Vector2i) -> void:
	var domino = domino_generator.instantiate()
	domino.grid_position = grid_position
	domino.grid_rotation = self.domino_grid_rotation
	domino.position = $DominoContainer/DominoGhost.position
	domino.rotation = $DominoContainer/DominoGhost.rotation
	domino.put_dots($DominoContainer/DominoGhost.dots_top, $DominoContainer/DominoGhost.dots_bot);
	$DominoContainer/DominoGrid.update_dot_values(domino)
	$DominoContainer/Dominoes.add_child(domino)

func remove_domino(domino: Domino) -> void:
	if domino != null:
		$DominoContainer/DominoGrid.remove_dot_values(domino)
		$DominoContainer/Dominoes.remove_child(domino)
		$DominoContainer/Deck.add_domino(Vector2i(domino.dots_top, domino.dots_bot))
