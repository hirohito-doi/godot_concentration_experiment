extends CanvasLayer

signal restart_game

func _ready():
	$AnimationPlayer.stop()

func show_result():
	$AnimationPlayer.play("show_result")
	

func _on_button_pressed() -> void:
	$AnimationPlayer.stop()
	restart_game.emit()
