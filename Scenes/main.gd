extends Node

const dominoScene = preload("res://Scenes/domino-sample.tscn")

func _input(event):
	if event is InputEventMouseMotion:
		print("Mouse moved: ", event)
		$DominoGhost.position = event.position
	if event is InputEventMouseButton:
		if (event.button_index == 1 and event.button_mask > 0):
			var dominoPiece = dominoScene.instantiate()
			dominoPiece.position = event.position
			add_child(dominoPiece)
