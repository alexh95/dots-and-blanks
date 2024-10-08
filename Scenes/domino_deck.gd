extends Node2D
## Holder object for the avaialble domino pieces that appear on screen and can be dragged and dropped on the grid.

const domino_generator: PackedScene = preload("res://Scenes/domino.tscn")

const init_domino_values: Array[Vector2i] = [
	Vector2i(1, 1), Vector2i(1, 2), Vector2i(1, 3),
	Vector2i(2, 2), Vector2i(2, 3), Vector2i(3, 3)
]

var selected_domino: Domino = null

func _ready() -> void:
	for index in range(init_domino_values.size()):
		add_domino(init_domino_values[index])

func get_domino_at_position(screen_position: Vector2i) -> Domino:
	for domino in $Dominoes.get_children(true):
		if domino.contains_point(screen_position):
			return domino
	return null

func highlight_domino(target_domino: Domino) -> void:
	for domino in $Dominoes.get_children(true):
		if domino == target_domino:
			domino.modulate = Color(0.0, 0.0, 0.8, 1.0)
		else:
			domino.modulate = Color(1.0, 1.0, 1.0, 1.0)
	if selected_domino != null:
		selected_domino.modulate = Color(1.0, 1.0, 0.0, 1.0)

func select_domino(target_domino: Domino) -> void:
	if selected_domino == target_domino:
		selected_domino = null
	else:
		selected_domino = target_domino
	if target_domino != null:
		target_domino.modulate = Color(1.0, 1.0, 0.0, 1.0)

func add_domino(dot_values: Vector2i) -> void:
	var domino = domino_generator.instantiate()
	domino.put_dots(dot_values.x, dot_values.y)
	$Dominoes.add_child(domino)
	recalculate_positions()

func remove_selected_domino() -> void:
	if selected_domino != null:
		$Dominoes.remove_child(selected_domino)
	selected_domino = null
	recalculate_positions()

func recalculate_positions() -> void:
	var dominoes = $Dominoes.get_children(true)
	var offset_center_x = 0.5 * dominoes.size() * 80 - 40
	for index in range(dominoes.size()):
		var domino = dominoes[index]
		var offset_x = index * 80 - offset_center_x
		domino.position = Vector2(offset_x, 270)
