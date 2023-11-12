extends Node

# see: https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html
var can_control = true

# true: 自分のターン false: 相手のターン
var current_turn:bool = true

var obtain_cards:Array = []
var obtain_cards_opponent:Array = []
