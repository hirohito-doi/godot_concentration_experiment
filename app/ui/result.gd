extends CanvasLayer

signal restart_game

func _ready():
	$AnimationPlayer.stop()

func show_result():
	var win_or_lose = "勝ち" if Global.obtain_cards.size() > Global.obtain_cards_opponent.size() else "負け"
	$Result/Description.text = "あなたの%s！" % win_or_lose
	$Result/Score.text = "%s - %s" % [str(Global.obtain_cards.size()), str(Global.obtain_cards_opponent.size())]
	$AnimationPlayer.play("show_result")
	

func _on_button_pressed() -> void:
	$AnimationPlayer.stop()
	restart_game.emit()
