extends Node

var utils = preload("res://common/utils.gd")

@export var card_scene: PackedScene

# トランプカード1組
@onready var deck:Array = utils.create_trump_deck()
var game_deck_origin:Array
var game_deck_current:Array
var obtain_cards:Array
var obtain_cards_opponent:Array
var revealing_cards_index:Array

func start_game() -> void:
	# ゲームに使用するカードを決定する
	game_deck_origin = utils.setup_game_deck(deck)
	game_deck_current = game_deck_origin.duplicate()
	
	# 場にカードを並べる
	for index in game_deck_origin.size():
		var card = game_deck_origin[index]
		var cardInstance = card_scene.instantiate()
		cardInstance.set_property(index, card.number, card.suit)
		cardInstance.connect('reversed_card', check_reversed_card)
		$Field.add_child(cardInstance)

func check_reversed_card(index:int) -> void:
	revealing_cards_index.push_back(index)
	
	# めくったカードが1枚目の場合は終了
	if(revealing_cards_index.size() == 2):
		$CheckTimer.start()


# 2枚めくった後に一定時間経過後、獲得または元に戻す
func _on_check_timer_timeout() -> void:
	var index_0 = revealing_cards_index[0]
	var index_1 = revealing_cards_index[1]
	var target_card_0 = game_deck_origin[index_0]
	var target_card_1 = game_deck_origin[index_1]
	
	# めくったカードの数字が一致するか確認
	if target_card_0["number"] == target_card_1["number"]:
		# 一致する
		# 場のカードの表示を消す
		$Field.get_child(index_0).hide_card()
		$Field.get_child(index_1).hide_card()
		
		# 自分の手札に加える
		obtain_cards.push_back(target_card_0)
		obtain_cards.push_back(target_card_1)
		
		# 終了判定
		if obtain_cards.size() == 2:
			$Result.show_result()
	else: 
		# 一致していなければ元に戻す
		$Field.get_child(index_0).undo_card()
		$Field.get_child(index_1).undo_card()
	
	# 初期化
	revealing_cards_index = []
