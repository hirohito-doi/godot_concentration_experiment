extends Control

signal reversed_card(index)

var index: int
var number: int
var suit: String

func set_property(new_index:int, new_number:int, new_suit:String) -> void:
	index = new_index
	number = new_number
	suit = new_suit
	
	$Face/Number.text = str(number)
	$Face/Suit.text = suit

# 手札に入ってきた場合の設定
func set_for_hand(new_number:int, new_suit:String) -> void:
	$ClickableArea.visible = false
	$Back.visible = false
	
	number = new_number
	suit = new_suit
	
	$Face/Number.text = str(number)
	$Face/Suit.text = suit


func undo_card() -> void:
	$AnimationPlayer.play("bad")
	$ClickableArea.disabled = false


func hide_card() -> void:
	$AnimationPlayer.play("good")
	$ClickableArea.visible = false


# カードをめくる
# 対戦相手が実行する場合もあるのでカードをクリックした際の処理とは分ける
func reverse_card() -> void:
	$ClickableArea.disabled = true
	$AnimationPlayer.play("reverse")


# カードクリック時に実行
func _on_clickable_area_pressed() -> void:
	if !Global.can_control or !Global.current_turn:
		return
	
	reverse_card()


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "reverse":
		reversed_card.emit(index)
