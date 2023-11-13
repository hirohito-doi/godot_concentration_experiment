extends CanvasLayer

signal start_game


func _on_button_pressed():
	start_game.emit()
