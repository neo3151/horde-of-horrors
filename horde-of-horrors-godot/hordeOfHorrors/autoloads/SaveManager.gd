extends Node

var save_path = "user://game_save.sav"

func _ready() -> void:
	pass # No initial setup needed

func save_game(data: Dictionary) -> void:
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()
		print("Game saved successfully!")
	else:
		push_error("Failed to save game.")

func load_game() -> Dictionary:
	var data: Dictionary = {}
	var file = FileAccess.open(save_path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		var parse_result = JSON.parse_string(content)
		if parse_result is Dictionary:
			data = parse_result
			print("Game loaded successfully!")
		else:
			push_error("Failed to parse save data.")
	else:
		print("No save file found.")
	return data

func delete_save() -> void:
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
		print("Save file deleted.")
	else:
		print("No save file to delete.")
