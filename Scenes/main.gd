extends Node

const domino_generator: PackedScene = preload("res://Scenes/domino.tscn")

var domino_grid_rotation: int = 0

@onready var tile_set_source_id = $DominoContainer/Tiles/LayerBack.tile_set.get_source_id(0)

const direction_offsets = [
	Vector2i.RIGHT,
	Vector2i.UP,
	Vector2i.LEFT,
	Vector2i.DOWN,
]

const domino_base_atlas_coords = Vector2i(0, 2)
const placement_primary_alternative = [2, 3, 0, 1]
const placement_secondary_alternative = [0, 1, 2, 3]

func _ready() -> void:
	$UI/NameAndVersion.text = 'dots-and-blanks ' + ProjectSettings.get_setting('application/config/version')
	$DominoContainer/DominoGhost.put_dots(1, 1)
	$UI/RotateButton.pressed.connect(self.rotate_domino)
	$UI/FullscreenButton.pressed.connect(self.toggle_fullscreen)
	$UI/ResetBoardButton.pressed.connect(self.reset_board)

func _input(event) -> void:
	if event is InputEventMouseMotion:
		handle_mouse_move(event)
	if event is InputEventMouseButton:
		handle_mouse_click(event)
	if event is InputEventKey:
		handle_key(event)

func handle_mouse_move(_event: InputEventMouseMotion) -> void:
	update_highlight()

func update_highlight() -> void:
	$DominoContainer/Tiles/LayerHighlight.clear()
	var global_mouse_position: Vector2 = $DominoContainer/Tiles.get_global_mouse_position()
	var tile_position: Vector2i = $DominoContainer/Tiles/LayerBack.local_to_map(global_mouse_position)
	if placement_in_bounds(tile_position):
		var valid = placement_valid(tile_position)
		placement_higlight(tile_position, valid)
	$DominoContainer/DominoGhost.position = global_mouse_position

func handle_mouse_click(event: InputEventMouseButton) -> void:
	if event.button_index == 1 and event.button_mask > 0:
		var global_mouse_position: Vector2 = $DominoContainer/Tiles.get_global_mouse_position()
		var tile_position: Vector2i = $DominoContainer/Tiles/LayerBack.local_to_map(global_mouse_position)
		if placement_valid(tile_position):
			place(tile_position)
	elif event.button_index == 2 and event.button_mask > 0:
		rotate_domino()
	elif event.button_index == 4 and event.button_mask > 0:
		rotate_domino(true)
	elif event.button_index == 5 and event.button_mask > 0:
		rotate_domino(false)

func handle_key(event: InputEventKey) -> void:
	if event.pressed && !event.echo:
		print(event)
	if event.keycode == 70 && event.pressed && !event.echo:
		toggle_fullscreen()
	if event.keycode == 82 && event.pressed && !event.echo:
		if event.ctrl_pressed:
			reset_board()
		else:
			rotate_domino(event.shift_pressed)

func placement_in_bounds(tile_position: Vector2i) -> bool:
	var secondary_tile_position = tile_position + direction_offsets[domino_grid_rotation]
	var tile_data: TileData = $DominoContainer/Tiles/LayerBack.get_cell_tile_data(tile_position)
	var secondary_tile_data: TileData = $DominoContainer/Tiles/LayerBack.get_cell_tile_data(secondary_tile_position)
	return tile_data != null and secondary_tile_data != null

func placement_valid(tile_position: Vector2i) -> bool:
	var secondary_tile_position = tile_position + direction_offsets[domino_grid_rotation]
	var tile_data_back: TileData = $DominoContainer/Tiles/LayerBack.get_cell_tile_data(tile_position)
	var secondary_tile_data_back: TileData = $DominoContainer/Tiles/LayerBack.get_cell_tile_data(secondary_tile_position)
	var tile_data_domino_back: TileData = $DominoContainer/Tiles/LayerDominoBack.get_cell_tile_data(tile_position)
	var secondary_tile_data_domino_back: TileData = $DominoContainer/Tiles/LayerDominoBack.get_cell_tile_data(secondary_tile_position)
	if tile_data_back != null and secondary_tile_data_back != null:
		var tile_back_blocking = tile_data_back.get_custom_data("blocking")
		var secondary_tile_back_blocking = secondary_tile_data_back.get_custom_data("blocking")
		var tile_domino_back_blocking = false if tile_data_domino_back == null else tile_data_domino_back.get_custom_data("blocking")
		var secondary_tile_domino_back_blocking = false if secondary_tile_data_domino_back == null else secondary_tile_data_domino_back.get_custom_data("blocking")
		var blocking = tile_back_blocking or secondary_tile_back_blocking or tile_domino_back_blocking or secondary_tile_domino_back_blocking
		return !blocking
	return false

func placement_higlight(tile_position: Vector2i, valid: bool) -> void:
	var secondary_tile_position = tile_position + direction_offsets[domino_grid_rotation]
	var atlas_coords = Vector2i(5, 2) if valid else Vector2i(4, 2)
	$DominoContainer/Tiles/LayerHighlight.set_cell(tile_position, tile_set_source_id, atlas_coords)
	$DominoContainer/Tiles/LayerHighlight.set_cell(secondary_tile_position, tile_set_source_id, atlas_coords)

func place(tile_position: Vector2i) -> void:
	var secondary_tile_position = tile_position + direction_offsets[domino_grid_rotation]
	$DominoContainer/Tiles/LayerDominoBack.set_cell(tile_position, tile_set_source_id, domino_base_atlas_coords, placement_primary_alternative[domino_grid_rotation])
	$DominoContainer/Tiles/LayerDominoBack.set_cell(secondary_tile_position, tile_set_source_id, domino_base_atlas_coords, placement_secondary_alternative[domino_grid_rotation])

func rotate_domino(counter_clockwise: bool = true) -> void:
	var rotation_delta = 1 if counter_clockwise else -1
	self.domino_grid_rotation = (self.domino_grid_rotation + rotation_delta) % 4
	$DominoContainer/DominoGhost.rotation = -0.5 * PI * self.domino_grid_rotation
	update_highlight()

func toggle_fullscreen() -> void:
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func reset_board() -> void:
	$DominoContainer/Tiles/LayerDominoBack.clear()
