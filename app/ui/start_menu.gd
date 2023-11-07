extends CanvasLayer

signal start_game


func _on_button_pressed():
	hide()
	start_game.emit()
