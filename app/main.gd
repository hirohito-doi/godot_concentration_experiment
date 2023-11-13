extends Node

func start_game() -> void:
	# 表示切り替え
	$StartMenu.hide()
	$Game.show()
	
	# ゲームの準備
	$Game.start_game()


func restart_game() -> void:
	$Result.hide()
	$Game.show()
	$Game.start_game()


func end_game() -> void:
	$Game.hide()
	$Result.show_result()
