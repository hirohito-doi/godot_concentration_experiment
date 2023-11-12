extends Node

var utils = preload("res://common/utils.gd")

@export var card_scene: PackedScene

# トランプカード1組
@onready var deck:Array = utils.create_trump_deck()
var game_deck_origin:Array
var remaining_cards_index:Array
var revealing_cards_index:Array = []

var opponent_memory_cards_index: Array = []

const OPPONENT_MEMORY_LIMIT = 6 # 対戦相手が何枚までめくったカードを記憶しているか


func start_game() -> void:
	# 初期化が必要なデータの対応
	Global.obtain_cards = []
	Global.obtain_cards_opponent = []
	Global.current_turn = true
	
	# ゲーム情報を表示
	$GameInfo.set_info();
	$FieldBackground.visible = true
	
	# ゲームに使用するカードを決定する
	game_deck_origin = utils.setup_game_deck(deck)
	# まだ取得していないカードのindexを配列に格納する
	for i in range(utils.FIELD_CARD_LIMIT):
		remaining_cards_index.append(i)
	
	# 場にカードを並べる
	set_cards()


func restart_game() -> void:
	# 場のカードインスタンスを削除
	for c in $Field.get_children():
		$Field.remove_child(c)
		c.queue_free()
	
	# 通常のゲーム開始メソッドを実行する
	start_game()


func set_cards() -> void:
	# 場にカードを置く	
	var index = $Field.get_child_count()
	var card = game_deck_origin[index]
	var cardInstance = card_scene.instantiate()
	cardInstance.set_property(index, card.number, card.suit)
	cardInstance.connect('reversed_card', check_reversed_card)
	$Field.add_child(cardInstance)
	
	# まだ配置する余裕があればタイマーを作動させる
	if $Field.get_child_count() != utils.FIELD_CARD_LIMIT:
		$PutCardTimer.start()


func check_reversed_card(index:int) -> void:
	revealing_cards_index.push_back(index)
	
	# めくったカードが2枚目の場合は判定時間を設ける
	if(revealing_cards_index.size() == 2):
		$CheckTimer.start()
	else: 
		Global.can_control = true


# 2枚めくった後に一定時間経過後、獲得または元に戻す
func _on_check_timer_timeout() -> void:
	var target_hands = Global.obtain_cards if Global.current_turn else Global.obtain_cards_opponent
	
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
		
		# 残っているカードのリストから削除する
		utils.remove_element_if_condition_matches(remaining_cards_index, index_0)
		utils.remove_element_if_condition_matches(remaining_cards_index, index_1)
		
		# 自分・または相手の手札に加える
		target_hands.push_back(target_card_0)
		target_hands.push_back(target_card_1)
		$GameInfo.get_cards(target_card_0, target_card_1)
		
		# 終了判定
		if Global.obtain_cards.size() + Global.obtain_cards_opponent.size() == utils.FIELD_CARD_LIMIT:
			$ThinkingTimer.stop()
			$GameInfo.end_game()
			$FieldBackground.visible = false
			$Result.show_result()
	else: 
		# 一致していなければ元に戻す
		$Field.get_child(index_0).undo_card()
		$Field.get_child(index_1).undo_card()
		
		# ターン権を変更する
		toggle_current_turn()
	
	# 対戦相手にめくったカードを記憶させる
	memory_reversed_card_by_opponent()
	# 初期化
	revealing_cards_index = []
	#クリック可能に戻す
	Global.can_control = true


# 対戦相手の行動実行
func _on_thinking_timer_timeout() -> void:
	reverse_card_by_opponent()


func toggle_current_turn() -> void:
	Global.current_turn = !Global.current_turn
	
	if Global.current_turn:
		# 自分のターンになった場合
		$ThinkingTimer.stop()
	else:
		# 相手ターンになった場合
		$ThinkingTimer.start()

# めくられたカードを対戦相手が記憶する
func memory_reversed_card_by_opponent() -> void:
	var new_opponent_memory_card = revealing_cards_index.duplicate()
	
	# 重複していなければ、元の記憶していたカードのインデックスを追加する
	for item in  opponent_memory_cards_index:
		if not item in new_opponent_memory_card:
			new_opponent_memory_card.append(item)

	# 覚えているカードを更新
	var count = 0
	opponent_memory_cards_index = new_opponent_memory_card.filter(func(item):
		# すでに取得されたものは除外する
		return item in remaining_cards_index
	).filter(func(item):
		# 一定確率で覚えたカードを忘れる
		# 記憶の限界を超える量であれば確実に忘れる
		if count > (OPPONENT_MEMORY_LIMIT - 1):
			return false
		
		# 後ろの内容程忘れやすくする
		# 覚えている確率: 直近のカードが一番高く、以降覚えている確率が減っていく
		var val = 70 - (count * 20) 
		count += 1
		return val > randi_range(0, 100)
	)

# 対戦相手がカードをめくる
func reverse_card_by_opponent() -> void:
	var target_card_index
	# FIXME 配列の範囲外を指定するとエラーになる？後で調べる
	# var first_revealing_card_index = revealing_cards_index[0]
	var first_revealing_card_index
	if revealing_cards_index.size() > 0:
		first_revealing_card_index = revealing_cards_index[0]

	# 記憶しているカードの後ろから検索したいのでコピーして順序を逆にする	
	var searching_cards_index = opponent_memory_cards_index.duplicate()
	searching_cards_index.reverse()
	
	# 記憶から一致するカードを探す
	if(first_revealing_card_index == null):
		# 初手
		# 記憶しているカードで一致するカードがあるか調べる
		for i in range(searching_cards_index.size()):
			var searching_card_index_1 = searching_cards_index[i]
			var searching_card_number_1 = game_deck_origin[searching_card_index_1]["number"]
			for j in range(i+1, searching_cards_index.size()):
				var serching_card_index_2 = searching_cards_index[j]
				var searching_card_number_2 = game_deck_origin[serching_card_index_2]["number"]
				if(searching_card_number_1 == searching_card_number_2):
					target_card_index = searching_card_index_1
					break
			if target_card_index != null:
				break
	else:
		# 2枚目
		# めくったカードと一致するカードがあるか調べる
		for i in range(searching_cards_index.size()):
			# 調べるカードがめくったカードであれば処理を飛ばす
			var searching_card_index = searching_cards_index[i]
			if first_revealing_card_index == searching_card_index:
				continue
			
			var searching_card_number_1 = game_deck_origin[searching_card_index]["number"]
			var searching_card_number_2 = game_deck_origin[first_revealing_card_index]["number"]
			if(searching_card_number_1 == searching_card_number_2):
				target_card_index =searching_card_index
				break

	# 特何もなければランダムに決定する
	if(target_card_index == null):
		#  TODO 現在めくっているカードや記憶していカードは除外する
		var selectable_cards_index = remaining_cards_index.filter(func (item):
			if(!first_revealing_card_index):
				return true
			return item != first_revealing_card_index
		)
		target_card_index = selectable_cards_index[randi() %selectable_cards_index.size()]

	# カードをめくる
	$Field.get_child(target_card_index).reverse_card()
