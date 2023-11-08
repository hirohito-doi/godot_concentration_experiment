extends CanvasLayer

func _ready():
	$AnimationPlayer.stop()

func show_result():
	$AnimationPlayer.play("show_result")
