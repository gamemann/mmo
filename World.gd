extends Node2D

const CharacterScene = preload("res://Character.tscn")


var player = null


func setup_server():
	EventBus.connect("player_added", self, "_on_player_added")
	
	
func _on_player_added(id, info):
	_add_character(id, info["name"], info["template"], Vector2(500, 300), false)


func _add_character(char_id, name, template, position, is_puppet):
	var new_character = CharacterScene.instance()	
	new_character.id = char_id
	new_character.is_puppet = is_puppet
	new_character.name = str(char_id)
	new_character.set_char_name(name)
	new_character.template = template
	new_character.get_node("Shape").frames = Assets.character_sprites[template]
	new_character.position = position		
	$Map/Characters.add_child(new_character)
	return new_character

	
func _process(delta):
	if Network.is_server:
		var game_state = {}
		for char_node in $Map/Characters.get_children():
			game_state[char_node.id] = char_node.dump_state()
			
		rpc_unreliable("update_game", game_state)
		
		
func get_character(char_id):
	return $Map/Characters.get_node_or_null(str(char_id))
		

remote func update_game(game_state):
	for char_id in game_state:
		var char_state = game_state[char_id]
		var char_node = get_character(char_id)
		if not char_node:			
			char_node = _add_character(char_id, char_state.name, char_state.template, char_state.position, true)
			if char_id == get_tree().get_network_unique_id():
				player = char_node
		char_node.update_state(game_state[char_id])		
