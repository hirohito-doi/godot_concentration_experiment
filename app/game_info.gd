extends CanvasLayer

@export var card_scene: PackedScene

func _process(delta: float) -> void:
	var turn_label = "あなた" if Global.current_turn else "あいて"
	$CurrentTurnLabel.text = "%sのターンです" % turn_label
	
	$PlayerInfoContainer/Score.text = str(Global.obtain_cards.size())
	$OpponentInfoContainer/Score.text = str(Global.obtain_cards_opponent.size())


func set_info() -> void:
	visible = true


func end_game() -> void:
	visible = false
	
	for c in $PlayerInfoContainer/CardArea.get_children():
		$PlayerInfoContainer/CardArea.remove_child(c)
		c.queue_free()
	for c in $OpponentInfoContainer/CardArea.get_children():
		$OpponentInfoContainer/CardArea.remove_child(c)
		c.queue_free()


func get_cards(card_0, card_1) -> void:
	var target_card_area = $PlayerInfoContainer/CardArea if Global.current_turn else $OpponentInfoContainer/CardArea
	
	var cardInstance_0 = card_scene.instantiate()
	cardInstance_0.set_for_hand(card_0.number, card_0.suit)
	target_card_area.add_child(cardInstance_0)
	
	var cardInstance_1 = card_scene.instantiate()
	cardInstance_1.set_for_hand(card_1.number, card_1.suit)
	target_card_area.add_child(cardInstance_1)
