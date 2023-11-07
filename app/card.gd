extends Control

var number:int
var suit: String

func set_property(new_number:int, new_suit:String) -> void:
	number = new_number
	suit = new_suit
	
	$Face/Number.text = str(number)
	$Face/Suit.text = suit
	
	

func _on_clickable_area_pressed() -> void:
	# カードをめくる
	$AnimationPlayer.play("reverse")
