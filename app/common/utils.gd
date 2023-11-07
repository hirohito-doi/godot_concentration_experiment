extends Script

enum SUIT { SPADE, HEART, DIAMOND, CLUB } 

# トランプを一組作成する
static func create_trump_deck() -> Array:
	var deck = []
	for suit in SUIT:
		for i in range(0, 13):
			deck.append({
				"suit": suit,
				"number": i+1
			})
	return deck
	

# ゲームに使用するデッキを設定する
static func setup_game_deck(deck:Array) -> Array:
	var tramp_deck = deck.duplicate() # 元のデッキに影響を与えないようコピーする
	var game_deck = []
	
	tramp_deck.shuffle()
	for i in range(0, 10):
		# 1枚カードをピックアップする
		var target_card = tramp_deck.pop_front()
		game_deck.push_back(target_card)
		
		# 同じ数字のカードを探す
		for j in range(0, tramp_deck.size()):
			var searching_card = tramp_deck[j]
			if target_card["number"] == searching_card["number"]:
				tramp_deck.remove_at(j)
				game_deck.push_back(searching_card)
				break
	
	game_deck.shuffle()
	return game_deck
