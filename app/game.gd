extends Node


var utils = preload("res://common/utils.gd")

signal game_finished

@export var card_scene: PackedScene

# トランプカード1組
@onready var deck:Array = utils.create_trump_deck()
var game_deck_origin:Array
var remaining_card_indices:Array
var revealing_card_indices:Array = []

var opponent_memory_card_indices: Array = []

# 対戦相手が何枚までめくったカードを記憶しているか
const OPPONENT_MEMORY_LIMIT = 6

# カードを場に並べる処理の途中か
var is_setting_cards:bool = false 


func _ready():
	# シーンが直接再生された場合
	if get_tree().get_current_scene() == self:
		start_game()
		

func _process(delta: float) -> void:
	if is_setting_cards:
		set_card_to_field()


func start_game() -> void:
	# 初期化が必要なデータの対応
	Global.obtain_cards = []
	Global.obtain_cards_opponent = []
	Global.current_turn = true
	update_turn_label()
	update_score_label()
	
	# ゲームに使用するカードを決定する
	game_deck_origin = utils.setup_game_deck(deck)
	# まだ取得していないカードのindexを配列に格納する
	for i in range(utils.FIELD_CARD_LIMIT):
		remaining_card_indices.append(i)
	
	# 場にカードを並べる
	set_card_to_field()


func end_game() -> void:
	# あらかじめシグナルを発する
	game_finished.emit()
	
	# ゲームの終了処理を実行する
	$ThinkingTimer.stop()
	
	# 場のカードインスタンスを削除
	for c in $Field.get_children():
		$Field.remove_child(c)
		c.queue_free()
		
	# 獲得したカードを削除
	for c in $GameInfo/PlayerInfoContainer/CardArea.get_children():
		$GameInfo/PlayerInfoContainer/CardArea.remove_child(c)
		c.queue_free()
	for c in $GameInfo/OpponentInfoContainer/CardArea.get_children():
		$GameInfo/OpponentInfoContainer/CardArea.remove_child(c)
		c.queue_free()


# 場にカードを置く(1枚ずつ)
func set_card_to_field() -> void:
	var index = $Field.get_child_count()
	var card = game_deck_origin[index]
	var cardInstance = card_scene.instantiate()
	cardInstance.set_property(index, card.number, card.suit)
	cardInstance.connect('reversed_card', check_reversed_card)
	$Field.add_child(cardInstance)
	
	# まだ配置する余裕があれば次フレームの処理で再度カードを置く処理を実行させる
	is_setting_cards = $Field.get_child_count() != utils.FIELD_CARD_LIMIT


# カードをめくった後に実行。カードの内容を確認する
func check_reversed_card(index:int) -> void:
	revealing_card_indices.push_back(index)
	
	# めくったカードが2枚目の場合は判定時間を設ける
	if(revealing_card_indices.size() == 2):
		$CheckTimer.start()
	else: 
		Global.can_control = true


# 2枚めくった後に一定時間経過後、獲得または元に戻す
func _on_check_timer_timeout() -> void:
	var target_hands = Global.obtain_cards if Global.current_turn else Global.obtain_cards_opponent
	
	# めくったカードの情報を取得する
	var index_0 = revealing_card_indices[0]
	var index_1 = revealing_card_indices[1]
	var target_card_0 = game_deck_origin[index_0]
	var target_card_1 = game_deck_origin[index_1]
	
	# めくったカードの数字が一致するか確認
	if target_card_0["number"] == target_card_1["number"]:
		# 一致する
		# 場のカードの表示を消す
		$Field.get_child(index_0).hide_card()
		$Field.get_child(index_1).hide_card()
		
		# 残っているカードのリストから削除する
		utils.remove_element_if_condition_matches(remaining_card_indices, index_0)
		utils.remove_element_if_condition_matches(remaining_card_indices, index_1)
		
		# 自分・または相手の手札に加える
		target_hands.push_back(target_card_0)
		target_hands.push_back(target_card_1)
		get_cards(target_card_0, target_card_1)
		
		# ゲームの終了判定
		if Global.obtain_cards.size() + Global.obtain_cards_opponent.size() == utils.FIELD_CARD_LIMIT:
			end_game()	
	else: 
		# 一致していなければ元に戻す
		$Field.get_child(index_0).undo_card()
		$Field.get_child(index_1).undo_card()
		
		# ターン権を変更する
		toggle_current_turn()
	
	# 対戦相手にめくったカードを記憶させる
	# カードが揃って手札にいった場合でも、記憶の内容を更新するため実行する
	memory_reversed_card_by_opponent()
	# めくったカードを空に戻す
	revealing_card_indices = []
	#クリック可能に戻す
	Global.can_control = true


func get_cards(card_0, card_1) -> void:
	var target_card_area = $GameInfo/PlayerInfoContainer/CardArea if Global.current_turn else $GameInfo/OpponentInfoContainer/CardArea
	
	var cardInstance_0 = card_scene.instantiate()
	cardInstance_0.set_for_hand(card_0.number, card_0.suit)
	target_card_area.add_child(cardInstance_0)
	
	var cardInstance_1 = card_scene.instantiate()
	cardInstance_1.set_for_hand(card_1.number, card_1.suit)
	target_card_area.add_child(cardInstance_1)

	# 手札枚数の更新
	update_score_label()


# 対戦相手の行動実行
func _on_thinking_timer_timeout() -> void:
	reverse_card_by_opponent()
	

# ターンの入れ替え
func toggle_current_turn() -> void:
	Global.current_turn = !Global.current_turn
	
	# ターン表示の更新
	update_turn_label()
	
	# 対戦相手の思考タイマーの作動状態切り替え
	if Global.current_turn:
		$ThinkingTimer.stop()
	else:
		$ThinkingTimer.start()


# めくられたカードを対戦相手が記憶する
func memory_reversed_card_by_opponent() -> void:
	var new_opponent_memory_card = revealing_card_indices.duplicate()
	
	# 重複していなければ、元の記憶していたカードのインデックスを追加する
	for item in  opponent_memory_card_indices:
		if not item in new_opponent_memory_card:
			new_opponent_memory_card.append(item)

	# 覚えているカードを更新
	var count = 0
	opponent_memory_card_indices = new_opponent_memory_card.filter(func(item):
		# すでに取得されたものは除外する
		return item in remaining_card_indices
	).filter(func(item):
		# 一定確率で覚えたカードを忘れる
		# 記憶の限界を超える量であれば確実に忘れる
		if count > (OPPONENT_MEMORY_LIMIT - 1):
			return false
		
		# 後ろの内容程忘れやすくする
		# 覚えている確率: 直近のカードが一番高く、以降覚えている確率が減っていく
		var val = 60 - (count * 10) 
		count += 1
		return val > randi_range(0, 100)
	)

# 対戦相手がカードをめくる
func reverse_card_by_opponent() -> void:
	var target_card_index
	# FIXME 配列の範囲外を指定するとエラーになる？後で調べる
	# var first_revealing_card_index = revealing_card_indices[0]
	var first_revealing_card_index
	if revealing_card_indices.size() > 0:
		first_revealing_card_index = revealing_card_indices[0]

	# 記憶しているカードの後ろから検索したいのでコピーして順序を逆にする	
	var searching_card_indices = opponent_memory_card_indices.duplicate()
	searching_card_indices.reverse()
	
	# 記憶から一致するカードを探す
	if(first_revealing_card_index == null):
		# 初手
		# 記憶しているカードで一致するカードがあるか調べる
		for i in range(searching_card_indices.size()):
			var searching_card_index_1 = searching_card_indices[i]
			var searching_card_number_1 = game_deck_origin[searching_card_index_1]["number"]
			for j in range(i+1, searching_card_indices.size()):
				var serching_card_index_2 = searching_card_indices[j]
				var searching_card_number_2 = game_deck_origin[serching_card_index_2]["number"]
				if(searching_card_number_1 == searching_card_number_2):
					target_card_index = searching_card_index_1
					break
			if target_card_index != null:
				break
	else:
		# 2枚目
		# めくったカードと一致するカードがあるか調べる
		for searching_card_index in searching_card_indices:
			if first_revealing_card_index == searching_card_index:
				continue
			
			var searching_card_number_1 = game_deck_origin[searching_card_index]["number"]
			var searching_card_number_2 = game_deck_origin[first_revealing_card_index]["number"]
			if(searching_card_number_1 == searching_card_number_2):
				target_card_index =searching_card_index
				break

	# 特何もなければランダムに決定する
	if(target_card_index == null):
		var selectable_cards_index = remaining_card_indices.filter(func (index):
			# 現在めくっているカードや記憶していカードは除外する
			if searching_card_indices.has(index):
				return false
			return index != first_revealing_card_index
		)
		target_card_index = selectable_cards_index[randi() %selectable_cards_index.size()]

	# カードをめくる
	$Field.get_child(target_card_index).reverse_card()
	

func update_turn_label() -> void:
	var turn_label = "あなた" if Global.current_turn else "あいて"
	$GameInfo/CurrentTurnLabel.text = "%sのターンです" % turn_label
	
	
func update_score_label() -> void:
	$GameInfo/PlayerInfoContainer/Score.text = str(Global.obtain_cards.size())
	$GameInfo/OpponentInfoContainer/Score.text = str(Global.obtain_cards_opponent.size())
