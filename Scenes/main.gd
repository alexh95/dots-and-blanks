extends Node

const domino_generator: PackedScene = preload("res://Scenes/domino.tscn")

var domino_grid_rotation: int = 0
var tile_position_deck_selected: Vector2i

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
	$DominoContainer/DominoGhost.visible = false
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
	elif removal_valid(tile_position):
		removal_highlight(tile_position)
	$DominoContainer/DominoGhost.position = global_mouse_position + Vector2(direction_offsets[self.domino_grid_rotation] * 8)
	update_highlight_deck()

func update_highlight_deck() -> void:
	$DominoContainer/Deck/LayerDominoHighlight.clear()
	if $DominoContainer/DominoGhost.visible:
		$DominoContainer/Deck/LayerDominoHighlight.set_cell(self.tile_position_deck_selected, tile_set_source_id, Vector2i(6, 2))
		$DominoContainer/Deck/LayerDominoHighlight.set_cell(self.tile_position_deck_selected + Vector2i.DOWN, tile_set_source_id, Vector2i(6, 2))

func handle_mouse_click(event: InputEventMouseButton) -> void:
	if event.button_index == 1 and event.button_mask > 0:
		var global_mouse_position: Vector2 = $DominoContainer/Tiles.get_global_mouse_position()
		var tile_position: Vector2i = $DominoContainer/Tiles/LayerBack.local_to_map(global_mouse_position)
		if placement_valid(tile_position):
			place(tile_position)
		elif removal_valid(tile_position):
			remove(tile_position)
		deck_handle_click()
	elif event.button_index == 2 and event.button_mask > 0:
		rotate_domino()
	elif event.button_index == 4 and event.button_mask > 0:
		rotate_domino(true)
	elif event.button_index == 5 and event.button_mask > 0:
		rotate_domino(false)

func handle_key(event: InputEventKey) -> void:
	if event.pressed && !event.echo:
		print(event)
	if event.keycode == KEY_ESCAPE && event.pressed && !event.echo:
		$DominoContainer/DominoGhost.visible = false
	if event.keycode == KEY_F && event.pressed && !event.echo:
		toggle_fullscreen()
	if event.keycode == KEY_R && event.pressed && !event.echo:
		if event.ctrl_pressed:
			reset_board()
		else:
			rotate_domino(event.shift_pressed)

func placement_in_bounds(tile_position: Vector2i) -> bool:
	if !$DominoContainer/DominoGhost.visible: return false
	var secondary_tile_position = tile_position + direction_offsets[domino_grid_rotation]
	var tile_data: TileData = $DominoContainer/Tiles/LayerBack.get_cell_tile_data(tile_position)
	var secondary_tile_data: TileData = $DominoContainer/Tiles/LayerBack.get_cell_tile_data(secondary_tile_position)
	return tile_data != null and secondary_tile_data != null

func placement_valid(tile_position: Vector2i) -> bool:
	if !$DominoContainer/DominoGhost.visible: return false
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
	var dot_value_primary = $DominoContainer/DominoGhost.dots_primary
	var dot_value_secondary = $DominoContainer/DominoGhost.dots_secondary
	var secondary_tile_position = tile_position + direction_offsets[domino_grid_rotation]
	$DominoContainer/Tiles/LayerDominoBack.set_cell(tile_position, tile_set_source_id, domino_base_atlas_coords, placement_primary_alternative[domino_grid_rotation])
	$DominoContainer/Tiles/LayerDominoFront.set_cell(tile_position, tile_set_source_id, Vector2i(dot_value_primary, 0))
	$DominoContainer/Tiles/LayerDominoBack.set_cell(secondary_tile_position, tile_set_source_id, domino_base_atlas_coords, placement_secondary_alternative[domino_grid_rotation])
	$DominoContainer/Tiles/LayerDominoFront.set_cell(secondary_tile_position, tile_set_source_id, Vector2i(dot_value_secondary, 0))
	$DominoContainer/DominoGhost.visible = false

func removal_highlight(tile_position: Vector2i) -> void:
	var tile_alternative: int = $DominoContainer/Tiles/LayerDominoBack.get_cell_alternative_tile(tile_position)
	var secondary_tile_position = tile_position - direction_offsets[tile_alternative]
	$DominoContainer/Tiles/LayerHighlight.set_cell(tile_position, tile_set_source_id, Vector2i(4, 2))
	$DominoContainer/Tiles/LayerHighlight.set_cell(secondary_tile_position, tile_set_source_id, Vector2i(4, 2))

func removal_valid(tile_position: Vector2i) -> bool:
	if $DominoContainer/DominoGhost.visible: return false
	var tile_data_domino_back: TileData = $DominoContainer/Tiles/LayerDominoBack.get_cell_tile_data(tile_position)
	if tile_data_domino_back == null: return false
	var tile_alternative: int = $DominoContainer/Tiles/LayerDominoBack.get_cell_alternative_tile(tile_position)
	var secondary_tile_position = tile_position - direction_offsets[tile_alternative]
	var secondary_tile_data_domino_back = $DominoContainer/Tiles/LayerDominoBack.get_cell_tile_data(secondary_tile_position)
	if secondary_tile_data_domino_back == null: return false
	#var primary_dot_value = $DominoContainer/Tiles/LayerDominoFront.get_cell_tile_data(tile_position).get_custom_data("dot_value")
	#var secondary_dot_value = $DominoContainer/Tiles/LayerDominoFront.get_cell_tile_data(secondary_tile_position).get_custom_data("dot_value")
	return true

func remove(tile_position: Vector2i) -> void:
	if $DominoContainer/DominoGhost.visible: return
	var tile_alternative: int = $DominoContainer/Tiles/LayerDominoBack.get_cell_alternative_tile(tile_position)
	var secondary_tile_position = tile_position - direction_offsets[tile_alternative]
	$DominoContainer/Tiles/LayerDominoBack.erase_cell(tile_position)
	$DominoContainer/Tiles/LayerDominoFront.erase_cell(tile_position)
	$DominoContainer/Tiles/LayerDominoBack.erase_cell(secondary_tile_position)
	$DominoContainer/Tiles/LayerDominoFront.erase_cell(secondary_tile_position)
	print("todo remove domino piece")

func deck_handle_click() -> void:
	var global_mouse_position: Vector2 = $DominoContainer/Deck.get_global_mouse_position()
	var deck_tile_position: Vector2i = $DominoContainer/Deck/LayerDominoBack.local_to_map(global_mouse_position)
	var deck_tile_data: TileData = $DominoContainer/Deck/LayerDominoBack.get_cell_tile_data(deck_tile_position)
	if deck_tile_data != null:
		var deck_tile_alternative: int = $DominoContainer/Deck/LayerDominoBack.get_cell_alternative_tile(deck_tile_position)
		var deck_primary_tile_position: Vector2i
		var deck_secondary_tile_position: Vector2i
		if deck_tile_alternative == 1:
			deck_primary_tile_position = deck_tile_position
			deck_secondary_tile_position = deck_tile_position + Vector2i.DOWN
		else:
			deck_primary_tile_position = deck_tile_position + Vector2i.UP
			deck_secondary_tile_position = deck_tile_position
		var deck_primary_dot_value: int = $DominoContainer/Deck/LayerDominoFront.get_cell_tile_data(deck_primary_tile_position).get_custom_data("dot_value")
		var deck_secondary_dot_value: int = $DominoContainer/Deck/LayerDominoFront.get_cell_tile_data(deck_secondary_tile_position).get_custom_data("dot_value")
		$DominoContainer/DominoGhost.put_dots(deck_primary_dot_value, deck_secondary_dot_value)
		$DominoContainer/DominoGhost.visible = true
		tile_position_deck_selected = deck_primary_tile_position
		set_domino_rotation(3)

func rotate_domino(counter_clockwise: bool = true) -> void:
	var rotation_delta = 1 if counter_clockwise else -1
	var new_rotation = (self.domino_grid_rotation + rotation_delta) % 4
	set_domino_rotation(new_rotation)

func set_domino_rotation(rotation: int) -> void:
	self.domino_grid_rotation = rotation
	$DominoContainer/DominoGhost.rotation = -0.5 * PI * rotation
	update_highlight()

func toggle_fullscreen() -> void:
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func reset_board() -> void:
	$DominoContainer/Tiles/LayerDominoBack.clear()
	$DominoContainer/Tiles/LayerDominoFront.clear()
