extends Node

var utils = preload("res://common/utils.gd")

@export var card_scene: PackedScene

# トランプカード1組
@onready var deck = utils.create_trump_deck()


func start_game() -> void:
	# ゲームに使用するカードを決定する
	var game_deck = utils.setup_game_deck(deck)
	
	# 場にカードを並べる
	for card in game_deck:
		var cardInstance = card_scene.instantiate()
		cardInstance.set_property(card.number, card.suit)
		$Field.add_child(cardInstance)
