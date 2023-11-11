extends CanvasLayer

@export var card_scene: PackedScene

func _process(delta: float) -> void:
	$PlayerInfoContainer/Score.text = str(Global.obtain_cards.size())


func set_info() -> void:
	visible = true


func end_game() -> void:
	visible = false


func get_cards(card_0, card_1) -> void:
	var cardInstance_0 = card_scene.instantiate()
	cardInstance_0.set_for_hand(card_0.number, card_0.suit)
	$PlayerInfoContainer/CardArea.add_child(cardInstance_0)
	
	var cardInstance_1 = card_scene.instantiate()
	cardInstance_1.set_for_hand(card_1.number, card_1.suit)
	$PlayerInfoContainer/CardArea.add_child(cardInstance_1)
